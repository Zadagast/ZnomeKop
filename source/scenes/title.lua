-- Title / boot menu — classic handheld RPG presentation.

local gfx = playdate.graphics

TitleScene = {}
TitleScene.__index = TitleScene

local OPTIONS = { "New Game", "Continue", "About" }

function TitleScene.new()
    return setmetatable({
        selected = 1,
        about = false,
    }, TitleScene)
end

function TitleScene:enter()
    gfx.setDrawOffset(0, 0)
    gfx.sprite.removeAll()
    if not Save.exists() or Save.load().seed == nil then
        self.hasSave = false
        self.options = { "New Game", "About" }
    else
        self.hasSave = true
        self.options = OPTIONS
    end
    self.selected = 1
    self.about = false
end

function TitleScene:startNew()
    local seed = playdate.getSecondsSinceEpoch() & 0x7FFFFFFF
    if seed == 0 then
        seed = 1
    end
    Game.startSector(seed, true)
end

function TitleScene:continueGame()
    local data = Save.load()
    if data.seed == nil then
        self:startNew()
        return
    end
    Game.save = data
    Game.startSector(data.seed, false)
end

function TitleScene:update()
    if self.about then
        if playdate.buttonJustPressed(playdate.kButtonB) or playdate.buttonJustPressed(playdate.kButtonA) then
            self.about = false
        end
        return
    end

    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self.selected -= 1
        if self.selected < 1 then
            self.selected = #self.options
        end
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self.selected += 1
        if self.selected > #self.options then
            self.selected = 1
        end
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        local choice = self.options[self.selected]
        if choice == "New Game" then
            self:startNew()
        elseif choice == "Continue" then
            self:continueGame()
        elseif choice == "About" then
            self.about = true
        end
    end
end

function TitleScene:drawBackdrop()
    -- Soft route silhouette behind the menu
    gfx.setColor(gfx.kColorBlack)
    for x = 0, 400, 16 do
        gfx.drawLine(x, 150, x + 8, 140)
    end
    -- dustreed field
    for x = 20, 180, 5 do
        gfx.drawLine(x, 168, x, 210)
    end
    -- little outpost
    gfx.fillTriangle(250, 170, 280, 145, 310, 170)
    gfx.drawRect(255, 170, 50, 30)
    gfx.fillRect(275, 185, 10, 15)
end

function TitleScene:draw()
    gfx.clear(gfx.kColorWhite)
    self:drawBackdrop()

    UIWindow.drawBox(70, 28, 260, 52)
    gfx.drawTextAligned("*ZNOMEKOP*", 200, 36, kTextAlignment.center)
    gfx.drawTextAligned("Mars Specimen Ops", 200, 56, kTextAlignment.center)

    if self.about then
        UIWindow.drawBox(40, 96, 320, 110)
        gfx.drawTextInRect(
            "Explore Mars routes and outposts.\nCatch Znomes in the dustreed.\nTrain a party. Challenge deeper sectors.\n\nNo story required — just the loop.",
            54, 108, 292, 90
        )
        return
    end

    UIWindow.drawMenu("MENU", self.options, self.selected, 130, 100, 140)
    gfx.drawTextAligned("S=A   A=B   D-pad move", 200, 220, kTextAlignment.center)
end
