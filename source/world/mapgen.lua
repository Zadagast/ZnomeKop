-- Mars sector generator: ordered, clustered passes for readable maps.
--   1. cellular-automata cliff ridges
--   2. town plazas (5x5) with POI buildings
--   3. A* routes between towns (playdate.pathfinder, terrain-cost weighted)
--   4. solid dustreed fields beside routes
--   5. accent blobs, brine pools, spire groves
--   6. flood-fill connectivity repair
-- Route carving borrows the SDK Pathfinder example pattern (0BSD).

import "CoreLibs/object"

Mapgen = {}

local DIRS = {
    { 0, -1 },
    { 1, 0 },
    { 0, 1 },
    { -1, 0 },
}

local function isGround(tile)
    return Tiles.isDust(tile) or tile == Tiles.CANYON
        or tile == Tiles.CRATER
end

-- Sprinkle detail into the regolith. Mostly plain so open fields stay calm;
-- roughly one tile in five carries a rock or a crack.
local function scatterGround(grid, rng)
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            if Tiles.isDust(Grid.get(grid, x, y)) then
                local roll = rng:int(1, 10)
                local tile = Tiles.DUST
                if roll == 1 then
                    tile = Tiles.DUST_B
                elseif roll == 2 then
                    tile = Tiles.DUST_C
                end
                Grid.set(grid, x, y, tile)
            end
        end
    end
end

-- Lone cliff cells render as black squares, so demote them to boulders.
-- Then cliff cells with another cliff above become face tiles, giving
-- ridges a lit top edge over a rock body.
local function dressCliffs(grid)
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            if Grid.get(grid, x, y) == Tiles.WALL then
                local n = 0
                for i = 1, 4 do
                    if Tiles.isCliff(Grid.get(grid, x + DIRS[i][1], y + DIRS[i][2])) then
                        n += 1
                    end
                end
                if n == 0 then
                    Grid.set(grid, x, y, Tiles.BOULDER)
                end
            end
        end
    end

    for y = 2, grid.height do
        for x = 1, grid.width do
            if Grid.get(grid, x, y) == Tiles.WALL
                and Tiles.isCliff(Grid.get(grid, x, y - 1)) then
                Grid.set(grid, x, y, Tiles.CLIFF_FACE)
            end
        end
    end
end

local function setBorder(grid, tile)
    for x = 1, grid.width do
        Grid.set(grid, x, 1, tile)
        Grid.set(grid, x, grid.height, tile)
    end
    for y = 1, grid.height do
        Grid.set(grid, 1, y, tile)
        Grid.set(grid, grid.width, y, tile)
    end
end

-- Pass 1: cliff ridges ------------------------------------------------------

local function generateCliffs(grid, rng, cfg)
    local w, h = grid.width, grid.height
    local cells = Grid.new(w, h, false)
    for y = 2, h - 1 do
        for x = 2, w - 1 do
            if rng:chance(cfg.cliffSeedChance) then
                Grid.set(cells, x, y, true)
            end
        end
    end

    for _ = 1, cfg.caSteps do
        local nxt = Grid.new(w, h, false)
        for y = 2, h - 1 do
            for x = 2, w - 1 do
                local n = 0
                for oy = -1, 1 do
                    for ox = -1, 1 do
                        if not (ox == 0 and oy == 0) then
                            local v = Grid.get(cells, x + ox, y + oy)
                            -- Out-of-bounds counts as cliff so ridges hug the border
                            if v == nil or v == true then
                                n += 1
                            end
                        end
                    end
                end
                if Grid.get(cells, x, y) then
                    Grid.set(nxt, x, y, n >= cfg.caSurvive)
                else
                    Grid.set(nxt, x, y, n >= cfg.caBirth)
                end
            end
        end
        cells = nxt
    end

    -- Write ridges; drop isolated single-tile cliffs (noise)
    for y = 2, h - 1 do
        for x = 2, w - 1 do
            if Grid.get(cells, x, y) then
                local n = 0
                for i = 1, 4 do
                    if Grid.get(cells, x + DIRS[i][1], y + DIRS[i][2]) then
                        n += 1
                    end
                end
                if n >= 1 then
                    Grid.set(grid, x, y, Tiles.WALL)
                end
            end
        end
    end
end

-- Pass 2: towns --------------------------------------------------------------

local BUILDING_POIS = {
    [Tiles.OUTPOST] = true,
    [Tiles.LAB] = true,
    [Tiles.RUINS] = true,
}

local function stampTown(grid, cx, cy, poiTile, cfg)
    -- Rectangular plaza; building occupies the top rows with the door
    -- (the POI tile) opening south into the plaza.
    local r = cfg.plazaRadius
    for y = cy - r, cy + r + 1 do
        for x = cx - r - 1, cx + r + 1 do
            Grid.set(grid, x, y, Tiles.COLONY)
        end
    end

    if BUILDING_POIS[poiTile] then
        -- 3x2 footprint: top row + flanks solid, door center-bottom
        for x = cx - 1, cx + 1 do
            Grid.set(grid, x, cy - 1, Tiles.BUILDING)
        end
        Grid.set(grid, cx - 1, cy, Tiles.BUILDING)
        Grid.set(grid, cx + 1, cy, Tiles.BUILDING)
    end
    Grid.set(grid, cx, cy, poiTile)

    -- supply crates parked in the plaza's south-east corner
    Grid.set(grid, cx + r, cy + r, Tiles.DOME)

    -- A route avenue runs from the door through the plaza to an explicit
    -- approach point just outside town. This makes every road visibly end
    -- at a building rather than disappearing at a plaza edge.
    local approachY = cy + r + 2
    for y = cy + 1, approachY do
        Grid.set(grid, cx, y, Tiles.ROCK)
    end
    return cx, approachY
end

local function farEnough(pois, x, y, minDist)
    for i = 1, #pois do
        if Grid.chebyshev(pois[i].x, pois[i].y, x, y) < minDist then
            return false
        end
    end
    return true
end

local function placeTowns(grid, rng, cfg)
    local plan = {}
    for _ = 1, cfg.outpostCount do plan[#plan + 1] = Tiles.OUTPOST end
    for _ = 1, cfg.labCount do plan[#plan + 1] = Tiles.LAB end
    for _ = 1, cfg.tubeCount do plan[#plan + 1] = Tiles.TUBE end
    for _ = 1, cfg.ruinsCount do plan[#plan + 1] = Tiles.RUINS end
    rng:shuffle(plan)

    local margin = cfg.plazaRadius + 4
    local pois = {}
    for i = 1, #plan do
        for _try = 1, 120 do
            local x = rng:int(margin, grid.width - margin + 1)
            local y = rng:int(margin, grid.height - margin + 1)
            if farEnough(pois, x, y, cfg.poiMinDistance) then
                local approachX, approachY = stampTown(grid, x, y, plan[i], cfg)
                pois[#pois + 1] = {
                    x = x,
                    y = y,
                    doorX = x,
                    doorY = y,
                    approachX = approachX,
                    approachY = approachY,
                    tile = plan[i],
                    kind = Tiles.Info[plan[i]].poiType,
                }
                break
            end
        end
    end
    return pois
end

-- Pass 3: routes (A* with terrain costs) -------------------------------------

local function tileCost(tile, cfg)
    if tile == Tiles.BUILDING then
        return 1000 -- never route through buildings
    elseif Tiles.isCliff(tile) or tile == Tiles.SPIRE then
        return cfg.routeCostCliff
    elseif tile == Tiles.ROCK then
        return cfg.routeCostExisting
    elseif tile == Tiles.ENCOUNTER then
        return cfg.routeCostGrass
    end
    return cfg.routeCostGround
end

local function buildRouteGraph(grid, cfg)
    local w, h = grid.width, grid.height
    local graph = playdate.pathfinder.graph.new()
    local nodes = graph:addNewNodes(w * h)

    local function idx(x, y)
        return (y - 1) * w + x
    end

    for y = 1, h do
        for x = 1, w do
            nodes[idx(x, y)]:setXY(x, y)
        end
    end

    -- Edge weight = cost of entering the target cell. Border excluded.
    for y = 2, h - 1 do
        for x = 2, w - 1 do
            local node = nodes[idx(x, y)]
            for i = 1, 4 do
                local nx = x + DIRS[i][1]
                local ny = y + DIRS[i][2]
                if nx >= 2 and ny >= 2 and nx <= w - 1 and ny <= h - 1 then
                    local cost = tileCost(Grid.get(grid, nx, ny), cfg)
                    node:addConnectionToNodeWithXY(nx, ny, cost, false)
                end
            end
        end
    end

    return graph
end

local function isTownTile(tile)
    local info = Tiles.Info[tile]
    return tile == Tiles.COLONY or tile == Tiles.DOME
        or tile == Tiles.BUILDING or (info and info.poi)
end

local function stampRouteCell(grid, x, y)
    local tile = Grid.get(grid, x, y)
    if tile ~= nil and not isTownTile(tile) then
        Grid.set(grid, x, y, Tiles.ROCK)
    end
end

local function routeDistance(a, b)
    return math.abs(a.approachX - b.approachX)
        + math.abs(a.approachY - b.approachY)
end

local function edgeKey(a, b)
    if a > b then a, b = b, a end
    return a .. ":" .. b
end

-- Prim's algorithm over POI approach points. A minimum-spanning tree makes
-- every road necessary: remove one and a destination becomes disconnected.
local function buildRouteLinks(pois, rng, cfg)
    local links = {}
    if #pois < 2 then return links end

    local inTree = { [1] = true }
    local used = {}
    while #links < #pois - 1 do
        local bestA, bestB, bestDistance = nil, nil, math.huge
        for a = 1, #pois do
            if inTree[a] then
                for b = 1, #pois do
                    if not inTree[b] then
                        local d = routeDistance(pois[a], pois[b])
                        if d < bestDistance then
                            bestA, bestB, bestDistance = a, b, d
                        end
                    end
                end
            end
        end
        if not bestA then break end
        links[#links + 1] = { a = bestA, b = bestB }
        used[edgeKey(bestA, bestB)] = true
        inTree[bestB] = true
    end

    -- One optional loop reduces dead-end backtracking without turning the
    -- zone into an arbitrary web. Prefer the longest unused connection.
    if #pois >= 3 and rng:chance(cfg.routeLoopChance) then
        local loopA, loopB, longest = nil, nil, -1
        for a = 1, #pois - 1 do
            for b = a + 1, #pois do
                if not used[edgeKey(a, b)] then
                    local d = routeDistance(pois[a], pois[b])
                    if d > longest then
                        loopA, loopB, longest = a, b, d
                    end
                end
            end
        end
        if loopA then
            links[#links + 1] = { a = loopA, b = loopB, loop = true }
        end
    end
    return links
end

local function stampPassingBay(grid, x, y)
    stampRouteCell(grid, x, y)
    stampRouteCell(grid, x + 1, y)
    stampRouteCell(grid, x, y + 1)
    stampRouteCell(grid, x + 1, y + 1)
end

local function carveRoutes(grid, pois, rng, cfg)
    if #pois < 2 then
        return {}
    end
    local links = buildRouteLinks(pois, rng, cfg)
    local routes = {}

    for i = 1, #links do
        -- Rebuild between links so later routes prefer already-carved roads.
        local graph = buildRouteGraph(grid, cfg)
        local link = links[i]
        local a, b = pois[link.a], pois[link.b]
        local startNode = graph:nodeWithXY(a.approachX, a.approachY)
        local endNode = graph:nodeWithXY(b.approachX, b.approachY)
        local path = graph:findPath(startNode, endNode)
        if path then
            local cells = {}
            for p = 1, #path do
                local n = path[p]
                stampRouteCell(grid, n.x, n.y)
                cells[#cells + 1] = { x = n.x, y = n.y }

                -- Turns get a small passing bay. Straight roads stay one
                -- tile wide and legible.
                if p > 1 and p < #path then
                    local prev, nxt = path[p - 1], path[p + 1]
                    local dx1, dy1 = n.x - prev.x, n.y - prev.y
                    local dx2, dy2 = nxt.x - n.x, nxt.y - n.y
                    if dx1 ~= dx2 or dy1 ~= dy2 then
                        stampPassingBay(grid, n.x, n.y)
                    end
                end
            end
            routes[#routes + 1] = {
                fromPoi = link.a,
                toPoi = link.b,
                loop = link.loop or false,
                cells = cells,
            }
        end
    end
    return routes
end

-- Pass 4: dustreed fields ------------------------------------------------------

local function placeGrassFields(grid, pois, rng, cfg)
    -- gather route cells as anchors
    local anchors = {}
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            if Grid.get(grid, x, y) == Tiles.ROCK then
                anchors[#anchors + 1] = { x = x, y = y }
            end
        end
    end
    if #anchors == 0 then
        return
    end
    rng:shuffle(anchors)

    local placed = 0
    local ai = 1
    while placed < cfg.grassFieldCount and ai <= #anchors do
        local a = anchors[ai]
        ai += 1
        local fw = rng:int(cfg.grassFieldMinW, cfg.grassFieldMaxW)
        local fh = rng:int(cfg.grassFieldMinH, cfg.grassFieldMaxH)
        local ox = a.x + rng:pick({ -fw - 1, 2 })
        local oy = a.y + rng:pick({ -fh - 1, 2 })

        -- field must sit on open ground, not too close to towns
        local ok = true
        for y = oy, oy + fh - 1 do
            for x = ox, ox + fw - 1 do
                local t = Grid.get(grid, x, y)
                if t == nil or not isGround(t) then
                    ok = false
                    break
                end
            end
            if not ok then break end
        end
        if ok then
            for p = 1, #pois do
                if Grid.chebyshev(a.x, a.y, pois[p].x, pois[p].y) <= cfg.plazaRadius + 2 then
                    ok = false
                    break
                end
            end
        end

        if ok then
            for y = oy, oy + fh - 1 do
                for x = ox, ox + fw - 1 do
                    Grid.set(grid, x, y, Tiles.ENCOUNTER)
                end
            end
            placed += 1
        end
    end
end

-- Pass 5: accents, pools, groves ----------------------------------------------

local function stampDisk(grid, cx, cy, radius, tile, onlyIf)
    for y = cy - radius, cy + radius do
        for x = cx - radius, cx + radius do
            if Grid.inBounds(grid, x, y) then
                local dx, dy = x - cx, y - cy
                if dx * dx + dy * dy <= radius * radius then
                    local cur = Grid.get(grid, x, y)
                    if onlyIf == nil or onlyIf(cur) then
                        Grid.set(grid, x, y, tile)
                    end
                end
            end
        end
    end
end

local function placeAccents(grid, rng, cfg)
    local accents = { Tiles.CANYON, Tiles.CRATER }
    for _ = 1, cfg.accentBlobCount do
        local x = rng:int(4, grid.width - 3)
        local y = rng:int(4, grid.height - 3)
        local tile = rng:pick(accents)
        stampDisk(grid, x, y, cfg.accentBlobRadius, tile, function(t)
            return t == Tiles.DUST
        end)
    end
end

local function placePools(grid, rng, cfg)
    local placed = 0
    for _try = 1, 80 do
        if placed >= cfg.poolCount then
            break
        end
        local x = rng:int(3, grid.width - 3)
        local y = rng:int(3, grid.height - 3)
        local clear = true
        for oy = 0, 1 do
            for ox = 0, 1 do
                local t = Grid.get(grid, x + ox, y + oy)
                if t == nil or not isGround(t) then
                    clear = false
                    break
                end
            end
            if not clear then break end
        end
        if clear then
            Grid.set(grid, x, y, Tiles.POOL_TL)
            Grid.set(grid, x + 1, y, Tiles.POOL_TR)
            Grid.set(grid, x, y + 1, Tiles.POOL_BL)
            Grid.set(grid, x + 1, y + 1, Tiles.POOL_BR)
            placed += 1
        end
    end
end

local function placeSpireGroves(grid, rng, cfg)
    for _ = 1, cfg.spireGroveCount do
        local x = rng:int(3, grid.width - 2)
        local y = rng:int(3, grid.height - 2)
        local count = rng:int(cfg.spireGroveMin, cfg.spireGroveMax)
        for _s = 1, count do
            local t = Grid.get(grid, x, y)
            if t ~= nil and isGround(t) then
                Grid.set(grid, x, y, Tiles.SPIRE)
            end
            x = x + rng:int(-1, 1)
            y = y + rng:int(-1, 1)
            if x < 3 then x = 3 elseif x > grid.width - 2 then x = grid.width - 2 end
            if y < 3 then y = 3 elseif y > grid.height - 2 then y = grid.height - 2 end
        end
    end
end

-- Pass 6: connectivity ---------------------------------------------------------

local function floodWalkable(grid, sx, sy)
    local visited = Grid.new(grid.width, grid.height, false)
    local qx = table.create(64, 0)
    local qy = table.create(64, 0)
    local head, tail = 1, 1
    qx[1], qy[1] = sx, sy
    Grid.set(visited, sx, sy, true)
    local count = 1
    while head <= tail do
        local x, y = qx[head], qy[head]
        head += 1
        for i = 1, 4 do
            local nx, ny = x + DIRS[i][1], y + DIRS[i][2]
            if Grid.inBounds(grid, nx, ny) and not Grid.get(visited, nx, ny)
                and Tiles.isWalkable(Grid.get(grid, nx, ny)) then
                Grid.set(visited, nx, ny, true)
                tail += 1
                qx[tail], qy[tail] = nx, ny
                count += 1
            end
        end
    end
    return visited, count
end

local function carveLine(grid, x0, y0, x1, y1)
    local x, y = x0, y0
    while true do
        local tile = Grid.get(grid, x, y)
        if tile ~= nil and not Tiles.isWalkable(tile) and not isTownTile(tile) then
            Grid.set(grid, x, y, Tiles.ROCK)
        end
        if x == x1 and y == y1 then
            break
        end
        if x ~= x1 and (y == y1 or math.abs(x - x1) >= math.abs(y - y1)) then
            if x < x1 then x += 1 else x -= 1 end
        else
            if y < y1 then y += 1 else y -= 1 end
        end
    end
end

local function ensureConnectivity(grid, startX, startY, cfg)
    local visited = floodWalkable(grid, startX, startY)
    local repairs = 0
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            if Tiles.isWalkable(Grid.get(grid, x, y)) and not Grid.get(visited, x, y) then
                carveLine(grid, x, y, startX, startY)
                repairs += 1
                visited = floodWalkable(grid, startX, startY)
                if repairs >= cfg.maxConnectivityRepairs then
                    for yy = 1, grid.height do
                        for xx = 1, grid.width do
                            if Tiles.isWalkable(Grid.get(grid, xx, yy)) and not Grid.get(visited, xx, yy) then
                                Grid.set(grid, xx, yy, Tiles.WALL)
                            end
                        end
                    end
                    return repairs
                end
            end
        end
    end
    return repairs
end

-- ------------------------------------------------------------------------------

local function pickSpawn(pois)
    for i = 1, #pois do
        if pois[i].tile == Tiles.OUTPOST then
            return pois[i].x, pois[i].y + 1 -- doorstep, not inside the building
        end
    end
    if #pois > 0 then
        return pois[1].x, pois[1].y + 1
    end
    return 5, 5
end

function Mapgen.generate(seed, overrides)
    local cfg = {}
    for k, v in pairs(Generation) do
        cfg[k] = v
    end
    if overrides then
        for k, v in pairs(overrides) do
            cfg[k] = v
        end
    end

    local rng = RNG(seed)
    local grid = Grid.new(cfg.width, cfg.height, Tiles.DUST)
    local t0 = playdate.getCurrentTimeMilliseconds()

    -- Spire tree line around the sector (route tree border), like GB routes
    setBorder(grid, Tiles.SPIRE)
    generateCliffs(grid, rng, cfg)
    local pois = placeTowns(grid, rng, cfg)
    local routes = carveRoutes(grid, pois, rng, cfg)
    placeGrassFields(grid, pois, rng, cfg)
    placeAccents(grid, rng, cfg)
    placePools(grid, rng, cfg)
    placeSpireGroves(grid, rng, cfg)

    scatterGround(grid, rng)

    local spawnX, spawnY = pickSpawn(pois)
    if not Tiles.isWalkable(Grid.get(grid, spawnX, spawnY)) then
        Grid.set(grid, spawnX, spawnY, Tiles.COLONY)
    end

    local repairs = ensureConnectivity(grid, spawnX, spawnY, cfg)
    dressCliffs(grid)

    -- Final assert: towns intact after all carving
    for i = 1, #pois do
        Grid.set(grid, pois[i].x, pois[i].y, pois[i].tile)
    end

    local ms = playdate.getCurrentTimeMilliseconds() - t0
    local _, walkableCount = floodWalkable(grid, spawnX, spawnY)

    return {
        width = cfg.width,
        height = cfg.height,
        tiles = grid,
        pois = pois,
        routes = routes,
        spawnX = spawnX,
        spawnY = spawnY,
        seed = seed,
        stats = {
            ms = ms,
            repairs = repairs,
            walkable = walkableCount,
            poiCount = #pois,
        },
    }
end
