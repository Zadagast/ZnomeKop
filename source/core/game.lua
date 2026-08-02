-- Global game facade used by scenes.

Game = {
    save = nil,
    rng = nil,
    party = nil,
}

local function copyList(src)
    local out = {}
    for i = 1, #src do
        out[i] = src[i]
    end
    return out
end

local function starterParty()
    local g = Creatures.get("gritmite")
    return {
        {
            id = g.id,
            name = g.name,
            level = 3,
            hp = g.baseStats.hp,
            maxHp = g.baseStats.hp,
            stats = {
                atk = g.baseStats.atk,
                def = g.baseStats.def,
                spd = g.baseStats.spd,
            },
            moves = copyList(g.moves),
        },
    }
end

function Game.boot()
    playdate.display.setRefreshRate(30)
    playdate.graphics.setBackgroundColor(playdate.graphics.kColorWhite)
    Game.save = Save.load()
    Game.rng = RNG(playdate.getSecondsSinceEpoch())
    if Game.save.party == nil or #Game.save.party == 0 then
        Game.save.party = starterParty()
    end
    Game.party = Game.save.party
    State.switch(TitleScene.new())
end

function Game.healParty()
    for i = 1, #Game.party do
        local m = Game.party[i]
        m.hp = m.maxHp
    end
end

function Game.zoneById(zoneId)
    for i = 1, #Game.save.zones do
        local zone = Game.save.zones[i]
        if zone.id == zoneId then
            return zone, i
        end
    end
    return nil, nil
end

local function nextZoneSeed(zoneId)
    local seed = (playdate.getSecondsSinceEpoch() ~ (zoneId * 7919)) & 0x7FFFFFFF
    if seed == 0 then seed = zoneId end
    -- Avoid collisions even when zones are generated in the same second.
    local unique = false
    while not unique do
        unique = true
        for i = 1, #Game.save.zones do
            if Game.save.zones[i].seed == seed then
                seed = (seed + 104729) & 0x7FFFFFFF
                if seed == 0 then seed = 1 end
                unique = false
                break
            end
        end
    end
    return seed
end

function Game.createZone()
    local id = Game.save.nextZoneId or 1
    local zone = {
        id = id,
        seed = nextZoneSeed(id),
        name = string.format("Zone %02d", id),
        playerX = nil,
        playerY = nil,
    }
    Game.save.zones[#Game.save.zones + 1] = zone
    Game.save.nextZoneId = id + 1
    Game.save.currentZoneId = id
    Save.write(Game.save)
    Game.loadZone(id)
end

function Game.startNewGame()
    Game.save = Save.default()
    Game.save.party = starterParty()
    Game.party = Game.save.party
    Game.createZone()
end

function Game.saveCurrentZonePosition(x, y)
    local zone = Game.zoneById(Game.save.currentZoneId)
    if not zone then return end
    zone.playerX = x
    zone.playerY = y
    Save.write(Game.save)
end

function Game.updateCurrentZonePosition(x, y)
    local zone = Game.zoneById(Game.save.currentZoneId)
    if not zone then return end
    zone.playerX = x
    zone.playerY = y
end

function Game.loadZone(zoneId)
    local zone = Game.zoneById(zoneId)
    if not zone then
        if #Game.save.zones == 0 then
            Game.createZone()
        end
        return
    end

    Game.save.currentZoneId = zoneId
    Game.rng = RNG(zone.seed ~ 0xC0FFEE)
    local map = Mapgen.generate(zone.seed)
    local x, y = map.spawnX, map.spawnY
    if zone.playerX and zone.playerY then
        if Grid.inBounds(map.tiles, zone.playerX, zone.playerY)
            and Tiles.isWalkable(Grid.get(map.tiles, zone.playerX, zone.playerY)) then
            x = zone.playerX
            y = zone.playerY
        end
    end
    zone.playerX = x
    zone.playerY = y
    Save.write(Game.save)
    State.switch(ExploreScene.new(map, x, y, zone))
end
