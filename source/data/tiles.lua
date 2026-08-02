-- Data-driven Mars tile definitions.
-- Indices match source/images/tiles-table-16-16.png (1-based).

Tiles = {
    EMPTY = 1,
    ROCK = 2,       -- packed path / open plain
    DUST = 3,       -- dust plain
    CANYON = 4,
    LAVA = 5,
    BOULDER = 6,    -- boulder cluster obstacle
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
    BUILDING = 22,   -- solid footprint under 96x64 building props
    DUST_B = 23,     -- regolith variants; identical rules, different grit
    DUST_C = 24,
    CLIFF_FACE = 25, -- cliff body below a cliff top
}

Tiles.Info = {
    [Tiles.EMPTY] = { name = "Empty", solid = true, encounter = 0, poi = false },
    [Tiles.ROCK] = { name = "Route", solid = false, encounter = 0.0, poi = false },
    [Tiles.DUST] = { name = "Regolith", solid = false, encounter = 0.04, poi = false },
    [Tiles.CANYON] = { name = "Strata", solid = false, encounter = 0.06, poi = false },
    [Tiles.LAVA] = { name = "Vent Field", solid = false, encounter = 0.08, poi = false },
    [Tiles.BOULDER] = { name = "Boulders", solid = true, encounter = 0, poi = false },
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
    [Tiles.BUILDING] = { name = "Structure", solid = true, encounter = 0, poi = false },
    [Tiles.DUST_B] = { name = "Regolith", solid = false, encounter = 0.04, poi = false },
    [Tiles.DUST_C] = { name = "Regolith", solid = false, encounter = 0.04, poi = false },
    [Tiles.CLIFF_FACE] = { name = "Cliff", solid = true, encounter = 0, poi = false },
}

-- Ground variants are interchangeable; mapgen scatters them so open
-- terrain does not show a 32px stamp grid.
Tiles.DustVariants = { Tiles.DUST, Tiles.DUST_B, Tiles.DUST_C }

function Tiles.isDust(tileId)
    return tileId == Tiles.DUST or tileId == Tiles.DUST_B or tileId == Tiles.DUST_C
end

function Tiles.isCliff(tileId)
    return tileId == Tiles.WALL or tileId == Tiles.CLIFF_FACE
end

Tiles.Ground = {
    Tiles.ROCK,
    Tiles.DUST,
    Tiles.DUST_B,
    Tiles.DUST_C,
    Tiles.CANYON,
    Tiles.LAVA,
    Tiles.CRATER,
}

Tiles.Groups = {
    arid = { Tiles.ROCK, Tiles.DUST, Tiles.CRATER, Tiles.ENCOUNTER },
    canyon = { Tiles.CANYON, Tiles.ROCK, Tiles.DUST },
    volcanic = { Tiles.LAVA, Tiles.ROCK, Tiles.CRATER },
    cold = { Tiles.BOULDER, Tiles.ROCK, Tiles.DUST },
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
