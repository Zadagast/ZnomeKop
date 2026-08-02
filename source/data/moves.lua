-- Battle move definitions (data-driven stub for battle slice).

Moves = {
    byId = {},
}

local function define(def)
    Moves.byId[def.id] = def
end

define({ id = "scrape", name = "Scrape", power = 20, cost = 0, affinity = "silica", effect = nil })
define({ id = "dust_puff", name = "Dust Puff", power = 10, cost = 0, affinity = "silica", effect = "accuracy_down" })
define({ id = "ram", name = "Ram", power = 30, cost = 1, affinity = "silica", effect = nil })
define({ id = "stone_shell", name = "Stone Shell", power = 0, cost = 1, affinity = "silica", effect = "defend_up" })
define({ id = "ember_lash", name = "Ember Lash", power = 28, cost = 1, affinity = "plasma", effect = nil })
define({ id = "heat_haze", name = "Heat Haze", power = 0, cost = 1, affinity = "plasma", effect = "evade_up" })
define({ id = "rime_spike", name = "Rime Spike", power = 26, cost = 1, affinity = "cryo", effect = nil })
define({ id = "chill_veil", name = "Chill Veil", power = 0, cost = 1, affinity = "cryo", effect = "speed_down" })
define({ id = "ping", name = "Ping", power = 18, cost = 0, affinity = "signal", effect = nil })
define({ id = "static_wing", name = "Static Wing", power = 24, cost = 1, affinity = "signal", effect = nil })
define({ id = "scrap_shot", name = "Scrap Shot", power = 22, cost = 0, affinity = "mech", effect = nil })
define({ id = "oxidize", name = "Oxidize", power = 12, cost = 1, affinity = "toxic", effect = "sap" })

function Moves.get(id)
    return Moves.byId[id]
end
