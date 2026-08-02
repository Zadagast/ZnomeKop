-- Classic handheld RPG window chrome (double-border message boxes).

local gfx = playdate.graphics

UIWindow = {}

function UIWindow.drawBox(x, y, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x, y, w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(x, y, w, h)
    gfx.drawRect(x + 2, y + 2, w - 4, h - 4)
end

function UIWindow.drawMessage(text)
    local w, h = 368, 56
    local x, y = 16, 172
    UIWindow.drawBox(x, y, w, h)
    gfx.drawTextInRect(text, x + 10, y + 10, w - 20, h - 18)
end

function UIWindow.drawMenu(title, options, selected, x, y, w)
    local hasTitle = title ~= nil and title ~= ""
    local top = hasTitle and 26 or 10
    local h = top + 2 + #options * 18
    UIWindow.drawBox(x, y, w, h)
    if hasTitle then
        gfx.drawText(title, x + 10, y + 6)
    end
    for i = 1, #options do
        local rowY = y + top + (i - 1) * 18
        if i == selected then
            gfx.fillTriangle(x + 10, rowY + 2, x + 10, rowY + 12, x + 16, rowY + 7)
        end
        gfx.drawText(options[i], x + 22, rowY)
    end
end
