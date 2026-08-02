-- Deterministic xorshift32 RNG for reproducible sector generation.

class("RNG").extends()

function RNG:init(seed)
    if seed == nil or seed == 0 then
        seed = 0xA5A5A5A5
    end
    self.state = seed & 0xFFFFFFFF
end

function RNG:nextU32()
    local x = self.state
    x = x ~ ((x << 13) & 0xFFFFFFFF)
    x = x ~ ((x >> 17) & 0xFFFFFFFF)
    x = x ~ ((x << 5) & 0xFFFFFFFF)
    self.state = x & 0xFFFFFFFF
    return self.state
end

function RNG:float()
    return (self:nextU32() & 0xFFFFFF) / 0x1000000
end

function RNG:int(lo, hi)
    if hi < lo then
        lo, hi = hi, lo
    end
    local span = hi - lo + 1
    return lo + (self:nextU32() % span)
end

function RNG:chance(p)
    return self:float() < p
end

function RNG:pick(list)
    if #list == 0 then
        return nil
    end
    return list[self:int(1, #list)]
end

function RNG:shuffle(list)
    for i = #list, 2, -1 do
        local j = self:int(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end
