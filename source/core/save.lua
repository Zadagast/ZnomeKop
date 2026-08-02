-- Persistent save for party, collection, and exploration progress.

Save = {
    SLOT = "slot1",
}

local defaultData = {
    version = 2,
    zones = {},
    currentZoneId = nil,
    nextZoneId = 1,
    party = {},
    collection = {},
    unlocked = {
        sectors = {},
    },
    stats = {
        steps = 0,
        encounters = 0,
        catches = 0,
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = deepCopy(v)
    end
    return out
end

function Save.default()
    return deepCopy(defaultData)
end

function Save.exists()
    return playdate.datastore.read(Save.SLOT) ~= nil
end

function Save.load()
    local data = playdate.datastore.read(Save.SLOT)
    if data == nil then
        return Save.default()
    end

    -- v1 stored one sector directly on the root save. Preserve it as Zone 1.
    if (data.version or 1) < 2 then
        local zones = {}
        if data.seed ~= nil then
            zones[1] = {
                id = 1,
                seed = data.seed,
                name = "Zone 01",
                playerX = data.playerX,
                playerY = data.playerY,
            }
        end
        data.zones = zones
        data.currentZoneId = (#zones > 0) and 1 or nil
        data.nextZoneId = (#zones > 0) and 2 or 1
        data.version = 2
        data.seed = nil
        data.playerX = nil
        data.playerY = nil
        data.sectorX = nil
        data.sectorY = nil
    end

    -- Fill any missing keys from defaults.
    local base = Save.default()
    for k, v in pairs(base) do
        if data[k] == nil then
            data[k] = v
        end
    end
    return data
end

function Save.write(data)
    playdate.datastore.write(data, Save.SLOT)
end

function Save.clear()
    playdate.datastore.delete(Save.SLOT)
end
