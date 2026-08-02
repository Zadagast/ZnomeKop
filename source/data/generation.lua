-- Tunable parameters for Mars sector generation.
-- Tuned for classic outdoor "route + town" readability.

Generation = {
    -- Fewer tiles than the 16px prototype: 32px tiles are larger on-screen.
    width = 32,
    height = 24,

    -- Settlements / landmarks
    outpostCount = 2,
    labCount = 1,
    tubeCount = 1,
    ruinsCount = 1,

    -- Town plaza radius around buildings
    townRadius = 2,

    -- Road / route carving
    roadWidth = 1,

    -- Dustreed (encounter grass) patches near routes
    grassPatchCount = 10,
    grassPatchRadius = 2,
    grassDensity = 0.72,

    -- Outdoor blockers
    cliffChance = 0.10,
    spireChance = 0.045,
    frostPoolCount = 3,
    ventPatchCount = 2,

    -- Spacing
    poiMinDistance = 8,

    maxConnectivityRepairs = 60,
}
