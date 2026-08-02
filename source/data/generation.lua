-- Tunable parameters for Mars sector generation.
-- Ordered passes: cliffs -> towns -> routes -> grass -> features -> repair.

Generation = {
    width = 32,
    height = 24,

    -- Settlements (each gets a 5x5 plaza)
    outpostCount = 2,
    labCount = 1,
    tubeCount = 1,
    ruinsCount = 1,
    poiMinDistance = 9,
    plazaRadius = 2,

    -- Cliff ridges (cellular automata, 8-neighborhood)
    cliffSeedChance = 0.38,
    caSteps = 3,
    caBirth = 5,    -- empty cell becomes cliff at >= this many cliff neighbors
    caSurvive = 4,  -- cliff cell survives at >= this many cliff neighbors

    -- Route carving (A* edge costs; routes prefer open ground)
    routeCostGround = 10,
    routeCostExisting = 4,
    routeCostGrass = 14,
    routeCostCliff = 60,
    routeLoopChance = 0.65,

    -- Dustreed fields (solid rectangles beside routes)
    grassFieldCount = 4,
    grassFieldMinW = 3,
    grassFieldMaxW = 6,
    grassFieldMinH = 2,
    grassFieldMaxH = 4,

    -- Terrain accent blobs (canyon / crater / vent patches)
    accentBlobCount = 3,
    accentBlobRadius = 2,

    -- Features
    poolCount = 2,          -- 2x2 brine pools
    spireGroveCount = 3,    -- clusters of silica spires
    spireGroveMin = 3,
    spireGroveMax = 5,

    maxConnectivityRepairs = 40,
}
