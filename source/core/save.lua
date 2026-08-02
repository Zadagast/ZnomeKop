-- Persistent save for party, collection, and exploration progress.

Save = {
    SLOT = "slot1",
}

local defaultData = {
    version = 1,
    seed = nil,
    sectorX = 0,
    sectorY = 0,
    playerX = nil,
    playerY = nil,
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
