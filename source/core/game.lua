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

function Game.startSector(seed, resetPosition)
    Game.save.seed = seed
    Game.rng = RNG(seed ~ 0xC0FFEE)
    local map = Mapgen.generate(seed)
    local x, y = map.spawnX, map.spawnY
    if not resetPosition and Game.save.playerX and Game.save.playerY then
        if Grid.inBounds(map.tiles, Game.save.playerX, Game.save.playerY)
            and Tiles.isWalkable(Grid.get(map.tiles, Game.save.playerX, Game.save.playerY)) then
            x = Game.save.playerX
            y = Game.save.playerY
        end
    else
        Game.save.playerX = x
        Game.save.playerY = y
    end
    Save.write(Game.save)
    State.switch(ExploreScene.new(map, x, y))
end
