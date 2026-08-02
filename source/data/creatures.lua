-- Original Mars creature roster (Znomes). Data-driven stub for later slices.

Creatures = {
    byId = {},
    list = {},
}

local function define(def)
    Creatures.byId[def.id] = def
    Creatures.list[#Creatures.list + 1] = def
end

-- Types are original sci-fi affinities (not Pokémon types).
-- silica / plasma / cryo / toxic / signal / mech

define({
    id = "gritmite",
    name = "Gritmite",
    types = { "silica" },
    baseStats = { hp = 28, atk = 12, def = 10, spd = 14 },
    catchRate = 0.45,
    habitats = { "dust", "rock" },
    moves = { "scrape", "dust_puff" },
    description = "A pebble-sized burrower that rides dust storms.",
})

define({
    id = "basaltusk",
    name = "Basaltusk",
    types = { "silica" },
    baseStats = { hp = 40, atk = 16, def = 18, spd = 8 },
    catchRate = 0.30,
    habitats = { "canyon", "rock" },
    moves = { "ram", "stone_shell" },
    description = "Thick-plated grazer found along canyon shelves.",
})

define({
    id = "cindrel",
    name = "Cindrel",
    types = { "plasma" },
    baseStats = { hp = 26, atk = 18, def = 8, spd = 16 },
    catchRate = 0.35,
    habitats = { "lava", "crater" },
    moves = { "ember_lash", "heat_haze" },
    description = "A slender ember-wisp nesting in lava tubes.",
})

define({
    id = "frostil",
    name = "Frostil",
    types = { "cryo" },
    baseStats = { hp = 30, atk = 11, def = 14, spd = 12 },
    catchRate = 0.40,
    habitats = { "frost" },
    moves = { "rime_spike", "chill_veil" },
    description = "Ice-lattice crawler that forms on night-side frost.",
})

define({
    id = "voxbat",
    name = "Voxbat",
    types = { "signal" },
    baseStats = { hp = 24, atk = 14, def = 9, spd = 20 },
    catchRate = 0.38,
    habitats = { "ruins", "signal" },
    moves = { "ping", "static_wing" },
    description = "Echo-locating flyer attracted to abandoned transmitters.",
})

define({
    id = "rustling",
    name = "Rustling",
    types = { "mech", "toxic" },
    baseStats = { hp = 32, atk = 13, def = 15, spd = 10 },
    catchRate = 0.33,
    habitats = { "ruins", "colony" },
    moves = { "scrap_shot", "oxidize" },
    description = "Semi-organic scavenger built from scrap and spores.",
})

function Creatures.get(id)
    return Creatures.byId[id]
end

function Creatures.pickForHabitat(habitat, rng)
    local pool = {}
    for i = 1, #Creatures.list do
        local c = Creatures.list[i]
        for j = 1, #c.habitats do
            if c.habitats[j] == habitat then
                pool[#pool + 1] = c
                break
            end
        end
    end
    if #pool == 0 then
        return Creatures.list[1]
    end
    local idx = rng:int(1, #pool)
    return pool[idx]
end
