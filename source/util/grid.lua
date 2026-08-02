-- Lightweight 2D grid helpers (1-based x/y).

Grid = {}

function Grid.new(width, height, fill)
    local g = {
        width = width,
        height = height,
        data = table.create(width * height, 0),
    }
    if fill ~= nil then
        for i = 1, width * height do
            g.data[i] = fill
        end
    end
    return g
end

function Grid.index(g, x, y)
    return (y - 1) * g.width + x
end

function Grid.inBounds(g, x, y)
    return x >= 1 and y >= 1 and x <= g.width and y <= g.height
end

function Grid.get(g, x, y)
    if not Grid.inBounds(g, x, y) then
        return nil
    end
    return g.data[Grid.index(g, x, y)]
end

function Grid.set(g, x, y, value)
    if not Grid.inBounds(g, x, y) then
        return
    end
    g.data[Grid.index(g, x, y)] = value
end

function Grid.neighbors4(x, y)
    return {
        { x = x, y = y - 1 },
        { x = x + 1, y = y },
        { x = x, y = y + 1 },
        { x = x - 1, y = y },
    }
end

function Grid.chebyshev(x1, y1, x2, y2)
    local dx = x1 - x2
    if dx < 0 then dx = -dx end
    local dy = y1 - y2
    if dy < 0 then dy = -dy end
    if dx > dy then
        return dx
    end
    return dy
end
