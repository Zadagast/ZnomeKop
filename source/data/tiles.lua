-- Data-driven Mars tile definitions.
-- Indices match source/images/tiles-table-16-16.png (1-based).

Tiles = {
    EMPTY = 1,
    ROCK = 2,       -- packed path / open plain
    DUST = 3,       -- dust plain
    CANYON = 4,
    LAVA = 5,
    FROST = 6,      -- brine pool (water-like)
    COLONY = 7,     -- town plaza
    WALL = 8,       -- mountain / cliff
    OUTPOST = 9,
    LAB = 10,
    TUBE = 11,
    RUINS = 12,
    ENCOUNTER = 13, -- dustreed (tall-grass equivalent)
    DOME = 14,
    WALKWAY = 15,
    CRATER = 16,
    SPIRE = 17,     -- silica spire blocker (tree stand-in)
    POOL_TL = 18,   -- 2x2 brine pool corners (solid)
    POOL_TR = 19,
    POOL_BL = 20,
    POOL_BR = 21,
}

Tiles.Info = {
    [Tiles.EMPTY] = { name = "Empty", solid = true, encounter = 0, poi = false },
    [Tiles.ROCK] = { name = "Regolith Path", solid = false, encounter = 0.0, poi = false },
    [Tiles.DUST] = { name = "Dust Plain", solid = false, encounter = 0.04, poi = false },
    [Tiles.CANYON] = { name = "Canyon Shelf", solid = false, encounter = 0.06, poi = false },
    [Tiles.LAVA] = { name = "Vent Rock", solid = false, encounter = 0.08, poi = false },
    [Tiles.FROST] = { name = "Brine Pool", solid = true, encounter = 0, poi = false }, -- blocks like water
    [Tiles.COLONY] = { name = "Colony Plaza", solid = false, encounter = 0.0, poi = false },
    [Tiles.WALL] = { name = "Cliff", solid = true, encounter = 0, poi = false },
    [Tiles.OUTPOST] = { name = "Outpost", solid = false, encounter = 0.0, poi = true, poiType = "outpost" },
    [Tiles.LAB] = { name = "Research Lab", solid = false, encounter = 0.0, poi = true, poiType = "lab" },
    [Tiles.TUBE] = { name = "Lava Tube", solid = false, encounter = 0.0, poi = true, poiType = "tube" },
    [Tiles.RUINS] = { name = "Ruins", solid = false, encounter = 0.05, poi = true, poiType = "ruins" },
    [Tiles.ENCOUNTER] = { name = "Dustreed", solid = false, encounter = 0.22, poi = false },
    [Tiles.DOME] = { name = "Dome Court", solid = false, encounter = 0.0, poi = false },
    [Tiles.WALKWAY] = { name = "Walkway", solid = false, encounter = 0.0, poi = false },
    [Tiles.CRATER] = { name = "Crater Rim", solid = false, encounter = 0.05, poi = false },
    [Tiles.SPIRE] = { name = "Silica Spire", solid = true, encounter = 0, poi = false },
    [Tiles.POOL_TL] = { name = "Brine Pool", solid = true, encounter = 0, poi = false },
    [Tiles.POOL_TR] = { name = "Brine Pool", solid = true, encounter = 0, poi = false },
    [Tiles.POOL_BL] = { name = "Brine Pool", solid = true, encounter = 0, poi = false },
    [Tiles.POOL_BR] = { name = "Brine Pool", solid = true, encounter = 0, poi = false },
}

Tiles.Ground = {
    Tiles.ROCK,
    Tiles.DUST,
    Tiles.CANYON,
    Tiles.LAVA,
    Tiles.CRATER,
}

Tiles.Groups = {
    arid = { Tiles.ROCK, Tiles.DUST, Tiles.CRATER, Tiles.ENCOUNTER },
    canyon = { Tiles.CANYON, Tiles.ROCK, Tiles.DUST },
    volcanic = { Tiles.LAVA, Tiles.ROCK, Tiles.CRATER },
    cold = { Tiles.FROST, Tiles.ROCK, Tiles.DUST },
    built = { Tiles.COLONY, Tiles.WALKWAY, Tiles.DOME, Tiles.OUTPOST, Tiles.LAB, Tiles.RUINS },
}

function Tiles.isSolid(tileId)
    local info = Tiles.Info[tileId]
    return info == nil or info.solid
end

function Tiles.isWalkable(tileId)
    return not Tiles.isSolid(tileId)
end

function Tiles.encounterChance(tileId)
    local info = Tiles.Info[tileId]
    if not info then
        return 0
    end
    return info.encounter or 0
end

function Tiles.displayName(tileId)
    local info = Tiles.Info[tileId]
    if not info then
        return "Unknown"
    end
    return info.name
end
