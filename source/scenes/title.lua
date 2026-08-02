-- Title / boot menu: tile diorama backdrop + GB-style logo panel.

local gfx = playdate.graphics

TitleScene = {}
TitleScene.__index = TitleScene

local OPTIONS = { "New Game", "Continue", "About" }

local SCREEN_W, SCREEN_H = 400, 240

function TitleScene.new()
    return setmetatable({
        selected = 1,
        about = false,
    }, TitleScene)
end

function TitleScene:buildBackdrop()
    local bg = gfx.image.new(SCREEN_W, SCREEN_H, gfx.kColorWhite)

    local tiles = gfx.imagetable.new("images/tiles")
    local buildings = gfx.imagetable.new("images/buildings")
    local player = gfx.imagetable.new("images/player")
    local creatures = gfx.imagetable.new("images/creatures")

    gfx.pushContext(bg)

    local horizon = 128
    -- ground field
    local ground = tiles:getImage(Tiles.DUST)
    for y = horizon, SCREEN_H - 1, 32 do
        for x = 0, SCREEN_W - 1, 32 do
            ground:draw(x, y)
        end
    end
    -- spire tree line on the horizon
    local spire = tiles:getImage(Tiles.SPIRE)
    for x = 0, SCREEN_W - 1, 32 do
        spire:draw(x, horizon - 32)
    end
    -- dustreed field, left
    local reed = tiles:getImage(Tiles.ENCOUNTER)
    for y = SCREEN_H - 64, SCREEN_H - 32, 32 do
        for x = 0, 96, 32 do
            reed:draw(x, y)
        end
    end
    -- outpost building, right
    buildings:getImage(1):draw(SCREEN_W - 128, SCREEN_H - 80)
    -- explorer + a znome mid-field
    player:getImage(1):draw(SCREEN_W // 2 - 40, SCREEN_H - 64)
    creatures:getImage(1):draw(SCREEN_W // 2 + 8, SCREEN_H - 64)

    gfx.popContext()
    self.backdrop = bg
end

function TitleScene:enter()
    gfx.setDrawOffset(0, 0)
    gfx.sprite.removeAll()
    local saved = Save.load()
    if not Save.exists() or #saved.zones == 0 then
        self.hasSave = false
        self.options = { "New Game", "About" }
    else
        self.hasSave = true
        self.options = OPTIONS
    end
    self.selected = 1
    self.about = false
    self:buildBackdrop()
end

function TitleScene:startNew()
    Game.startNewGame()
end

function TitleScene:continueGame()
    local data = Save.load()
    if #data.zones == 0 then
        self:startNew()
        return
    end
    Game.save = data
    Game.party = Game.save.party
    Game.loadZone(data.currentZoneId or data.zones[1].id)
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

function TitleScene:draw()
    gfx.clear(gfx.kColorWhite)
    if self.backdrop then
        self.backdrop:draw(0, 0)
    end

    -- GB box-art logo panel
    UIWindow.drawBox(70, 16, 260, 54)
    gfx.drawTextAligned("*ZNOMEKOP*", 200, 26, kTextAlignment.center)
    gfx.drawTextAligned("Mars Specimen Ops", 200, 46, kTextAlignment.center)

    if self.about then
        UIWindow.drawBox(40, 84, 320, 116)
        gfx.drawTextInRect(
            "Explore Mars routes and outposts.\nCatch Znomes in the dustreed.\nTrain a party. Challenge deeper sectors.\n\nA: confirm/interact   B: menu/back",
            54, 96, 292, 96
        )
        return
    end

    UIWindow.drawMenu("", self.options, self.selected, 132, 80, 136)
end
