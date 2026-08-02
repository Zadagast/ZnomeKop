-- Exploration scene: map + player loop.

local gfx = playdate.graphics

ExploreScene = {}
ExploreScene.__index = ExploreScene

function ExploreScene.new(map, resumeX, resumeY)
    return setmetatable({
        map = map,
        resumeX = resumeX,
        resumeY = resumeY,
        menuOpen = false,
        menuIndex = 1,
        menu = { "Resume", "Save", "New Sector", "Title" },
    }, ExploreScene)
end

function ExploreScene:enter()
    gfx.sprite.removeAll()
    local x = self.resumeX or self.map.spawnX
    local y = self.resumeY or self.map.spawnY
    self.player = Player.new(x, y)
    self.world = World.new(self.map, self.player)
    self.world:showMessage("You arrive at a frontier outpost.\nThe dustreed whispers with signals.", 110)
end

function ExploreScene:exit()
    if self.world then
        self.world:destroy()
    end
end

function ExploreScene:saveGame()
    Game.save.seed = self.map.seed
    Game.save.playerX = self.player.tileX
    Game.save.playerY = self.player.tileY
    Save.write(Game.save)
    self.world:showMessage("Progress saved.")
    self.menuOpen = false
end

function ExploreScene:updateMenu()
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self.menuIndex -= 1
        if self.menuIndex < 1 then self.menuIndex = #self.menu end
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self.menuIndex += 1
        if self.menuIndex > #self.menu then self.menuIndex = 1 end
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
        self.menuOpen = false
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        local choice = self.menu[self.menuIndex]
        if choice == "Resume" then
            self.menuOpen = false
        elseif choice == "Save" then
            self:saveGame()
        elseif choice == "New Sector" then
            local seed = (self.map.seed + 7919) & 0x7FFFFFFF
            if seed == 0 then seed = 1 end
            Game.startSector(seed, true)
        elseif choice == "Title" then
            self:saveGame()
            State.switch(TitleScene.new())
        end
    end
end

function ExploreScene:update()
    if self.menuOpen then
        self:updateMenu()
        return
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        self.menuOpen = true
        self.menuIndex = 1
        return
    end

    self.world:update()
end

function ExploreScene:draw()
    self.world:draw()

    if self.menuOpen then
        gfx.setDrawOffset(0, 0)
        UIWindow.drawMenu("MENU", self.menu, self.menuIndex, 250, 28, 140)
    end
end
