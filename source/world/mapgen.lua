-- Outdoor Mars sector generator (classic route + town feel).
-- Hybrid method: towns -> roads -> grass patches -> blockers -> connectivity.
-- Lightweight constrained adjacency, Playdate-friendly.

import "CoreLibs/object"

Mapgen = {}

local DIRS = {
    { 0, -1 },
    { 1, 0 },
    { 0, 1 },
    { -1, 0 },
}

local function fill(grid, tile)
    for i = 1, grid.width * grid.height do
        grid.data[i] = tile
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

local function carveRoad(grid, x0, y0, x1, y1, tile)
    local x, y = x0, y0
    while true do
        local cur = Grid.get(grid, x, y)
        if cur == Tiles.WALL or cur == Tiles.SPIRE or cur == Tiles.FROST or cur == Tiles.DUST
            or cur == Tiles.CANYON or cur == Tiles.LAVA or cur == Tiles.CRATER or cur == Tiles.ENCOUNTER then
            Grid.set(grid, x, y, tile)
        elseif cur == Tiles.ROCK then
            Grid.set(grid, x, y, tile)
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

    local pois = {}
    for i = 1, #plan do
        local x, y
        for _try = 1, 80 do
            local tx = rng:int(4, grid.width - 3)
            local ty = rng:int(4, grid.height - 3)
            if farEnough(pois, tx, ty, cfg.poiMinDistance) then
                x, y = tx, ty
                break
            end
        end
        if x then
            -- Town apron: plaza + walkways (Pokemon-town readability)
            stampDisk(grid, x, y, cfg.townRadius, Tiles.COLONY, function(t)
                return t ~= Tiles.WALL
            end)
            for _, n in ipairs(Grid.neighbors4(x, y)) do
                if Grid.inBounds(grid, n.x, n.y) then
                    Grid.set(grid, n.x, n.y, Tiles.WALKWAY)
                end
            end
            -- Decorative dome tile nearby for outposts
            if plan[i] == Tiles.OUTPOST or plan[i] == Tiles.LAB then
                local dx = rng:pick({ -1, 1 })
                local dy = rng:pick({ -1, 1 })
                local dx2, dy2 = x + dx, y + dy
                if Grid.inBounds(grid, dx2, dy2) then
                    Grid.set(grid, dx2, dy2, Tiles.DOME)
                end
            end
            Grid.set(grid, x, y, plan[i])
            pois[#pois + 1] = {
                x = x,
                y = y,
                tile = plan[i],
                kind = Tiles.Info[plan[i]].poiType,
            }
        end
    end
    return pois
end

local function connectTowns(grid, pois)
    if #pois == 0 then
        return
    end
    for i = 2, #pois do
        carveRoad(grid, pois[i - 1].x, pois[i - 1].y, pois[i].x, pois[i].y, Tiles.ROCK)
    end
    -- loop a bit for nicer routes
    if #pois >= 3 then
        carveRoad(grid, pois[1].x, pois[1].y, pois[#pois].x, pois[#pois].y, Tiles.ROCK)
    end
    -- restore building tiles overwritten by roads
    for i = 1, #pois do
        Grid.set(grid, pois[i].x, pois[i].y, pois[i].tile)
    end
end

local function paintBaseTerrain(grid, rng)
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            local t = Grid.get(grid, x, y)
            if t == Tiles.ROCK then
                -- leave roads; convert some leftover plains to dust
                -- roads are painted after; initial fill is dust
            end
        end
    end
    -- soft biome speckles on open dust
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            if Grid.get(grid, x, y) == Tiles.DUST then
                local r = rng:float()
                if r < 0.08 then
                    Grid.set(grid, x, y, Tiles.CANYON)
                elseif r < 0.12 then
                    Grid.set(grid, x, y, Tiles.CRATER)
                end
            end
        end
    end
end

local function placeGrassPatches(grid, pois, rng, cfg)
    -- Prefer patches near roads but not inside towns.
    local candidates = {}
    for y = 3, grid.height - 2 do
        for x = 3, grid.width - 2 do
            if Grid.get(grid, x, y) == Tiles.ROCK then
                candidates[#candidates + 1] = { x = x, y = y }
            end
        end
    end
    if #candidates == 0 then
        return
    end
    rng:shuffle(candidates)

    local placed = 0
    local i = 1
    while placed < cfg.grassPatchCount and i <= #candidates do
        local c = candidates[i]
        i += 1
        local nearTown = false
        for p = 1, #pois do
            if Grid.chebyshev(c.x, c.y, pois[p].x, pois[p].y) <= cfg.townRadius + 1 then
                nearTown = true
                break
            end
        end
        if not nearTown then
            -- Offset patch beside the road
            local ox = c.x + rng:pick({ -2, -1, 1, 2, 0 })
            local oy = c.y + rng:pick({ -2, -1, 1, 2, 0 })
            stampDisk(grid, ox, oy, cfg.grassPatchRadius, Tiles.ENCOUNTER, function(t)
                return (t == Tiles.DUST or t == Tiles.CANYON or t == Tiles.CRATER)
                    and rng:chance(cfg.grassDensity)
            end)
            -- Also convert some dust around road to grass
            stampDisk(grid, ox, oy, cfg.grassPatchRadius, Tiles.ENCOUNTER, function(t)
                return t == Tiles.DUST and rng:chance(cfg.grassDensity)
            end)
            placed += 1
        end
    end
end

local function placeBlockers(grid, rng, cfg)
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            local t = Grid.get(grid, x, y)
            if t == Tiles.DUST or t == Tiles.CANYON or t == Tiles.CRATER then
                if rng:chance(cfg.cliffChance) then
                    Grid.set(grid, x, y, Tiles.WALL)
                elseif rng:chance(cfg.spireChance) then
                    Grid.set(grid, x, y, Tiles.SPIRE)
                end
            end
        end
    end

    -- Small brine pools (water-like obstacles)
    for _ = 1, cfg.frostPoolCount do
        local x = rng:int(3, grid.width - 2)
        local y = rng:int(3, grid.height - 2)
        stampDisk(grid, x, y, rng:int(1, 2), Tiles.FROST, function(t)
            return t == Tiles.DUST or t == Tiles.CANYON or t == Tiles.CRATER
        end)
    end

    -- Vent rock patches
    for _ = 1, cfg.ventPatchCount do
        local x = rng:int(3, grid.width - 2)
        local y = rng:int(3, grid.height - 2)
        stampDisk(grid, x, y, 2, Tiles.LAVA, function(t)
            return t == Tiles.DUST or t == Tiles.CRATER
        end)
    end
end

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

local function ensureConnectivity(grid, startX, startY, cfg)
    local visited = floodWalkable(grid, startX, startY)
    local repairs = 0
    for y = 2, grid.height - 1 do
        for x = 2, grid.width - 1 do
            if Tiles.isWalkable(Grid.get(grid, x, y)) and not Grid.get(visited, x, y) then
                carveRoad(grid, x, y, startX, startY, Tiles.ROCK)
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

local function pickSpawn(pois)
    for i = 1, #pois do
        if pois[i].tile == Tiles.OUTPOST then
            return pois[i].x, pois[i].y
        end
    end
    if #pois > 0 then
        return pois[1].x, pois[1].y
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

    setBorder(grid, Tiles.WALL)
    paintBaseTerrain(grid, rng)
    local pois = placeTowns(grid, rng, cfg)
    connectTowns(grid, pois)
    placeGrassPatches(grid, pois, rng, cfg)
    placeBlockers(grid, rng, cfg)

    -- Keep roads clear of blockers/grass
    -- Re-carve roads once more for clarity, then restore POIs.
    connectTowns(grid, pois)

    local spawnX, spawnY = pickSpawn(pois)
    if not Tiles.isWalkable(Grid.get(grid, spawnX, spawnY)) then
        Grid.set(grid, spawnX, spawnY, Tiles.OUTPOST)
    end

    local repairs = ensureConnectivity(grid, spawnX, spawnY, cfg)

    -- Final POI assert + clear immediate neighbors for doorstep
    for i = 1, #pois do
        local p = pois[i]
        Grid.set(grid, p.x, p.y, p.tile)
        for _, n in ipairs(Grid.neighbors4(p.x, p.y)) do
            if Grid.inBounds(grid, n.x, n.y) then
                local t = Grid.get(grid, n.x, n.y)
                if t == Tiles.WALL or t == Tiles.SPIRE or t == Tiles.FROST or t == Tiles.ENCOUNTER then
                    Grid.set(grid, n.x, n.y, Tiles.WALKWAY)
                end
            end
        end
    end

    local ms = playdate.getCurrentTimeMilliseconds() - t0
    local _, walkableCount = floodWalkable(grid, spawnX, spawnY)

    return {
        width = cfg.width,
        height = cfg.height,
        tiles = grid,
        pois = pois,
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
