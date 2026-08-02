-- Exploration scene: map + player loop.

local gfx = playdate.graphics

ExploreScene = {}
ExploreScene.__index = ExploreScene

function ExploreScene.new(map, resumeX, resumeY, zone)
    return setmetatable({
        map = map,
        zone = zone,
        resumeX = resumeX,
        resumeY = resumeY,
        menuOpen = false,
        menuMode = "main",
        menuIndex = 1,
        zoneIndex = 1,
        menu = { "Resume", "Save", "Zones", "Generate Zone", "Title" },
    }, ExploreScene)
end

function ExploreScene:enter()
    gfx.sprite.removeAll()
    local x = self.resumeX or self.map.spawnX
    local y = self.resumeY or self.map.spawnY
    self.player = Player.new(x, y)
    self.world = World.new(self.map, self.player)
    self.world:showMessage((self.zone and self.zone.name or "Zone") .. " loaded.", 80)
end

function ExploreScene:exit()
    if self.world then
        self.world:destroy()
    end
end

function ExploreScene:saveGame()
    Game.saveCurrentZonePosition(self.player.tileX, self.player.tileY)
    self.world:showMessage("Progress saved.")
    self.menuOpen = false
    self.menuMode = "main"
end

function ExploreScene:updateMainMenu()
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
        elseif choice == "Zones" then
            self.menuMode = "zones"
            self.zoneIndex = 1
            for i = 1, #Game.save.zones do
                if Game.save.zones[i].id == Game.save.currentZoneId then
                    self.zoneIndex = i
                    break
                end
            end
        elseif choice == "Generate Zone" then
            self.menuMode = "confirm"
        elseif choice == "Title" then
            self:saveGame()
            State.switch(TitleScene.new())
        end
    end
end

function ExploreScene:updateZoneMenu()
    local count = #Game.save.zones
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self.zoneIndex -= 1
        if self.zoneIndex < 1 then self.zoneIndex = count end
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self.zoneIndex += 1
        if self.zoneIndex > count then self.zoneIndex = 1 end
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
        self.menuMode = "main"
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        local zone = Game.save.zones[self.zoneIndex]
        if zone.id == Game.save.currentZoneId then
            self.menuOpen = false
            self.menuMode = "main"
        else
            Game.saveCurrentZonePosition(self.player.tileX, self.player.tileY)
            Game.loadZone(zone.id)
        end
    end
end

function ExploreScene:updateConfirmMenu()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        self.menuMode = "main"
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        Game.saveCurrentZonePosition(self.player.tileX, self.player.tileY)
        Game.createZone()
    end
end

function ExploreScene:updateMenu()
    if self.menuMode == "zones" then
        self:updateZoneMenu()
    elseif self.menuMode == "confirm" then
        self:updateConfirmMenu()
    else
        self:updateMainMenu()
    end
end

function ExploreScene:update()
    if self.menuOpen then
        self:updateMenu()
        return
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        self.menuOpen = true
        self.menuMode = "main"
        self.menuIndex = 1
        return
    end

    self.world:update()
end

function ExploreScene:draw()
    self.world:draw()

    if self.menuOpen then
        gfx.setDrawOffset(0, 0)
        if self.menuMode == "zones" then
            local visible = {}
            local startIndex = math.max(1, math.min(self.zoneIndex - 3, #Game.save.zones - 6))
            local endIndex = math.min(#Game.save.zones, startIndex + 6)
            for i = startIndex, endIndex do
                local zone = Game.save.zones[i]
                local marker = (zone.id == Game.save.currentZoneId) and "* " or "  "
                visible[#visible + 1] = marker .. zone.name
            end
            UIWindow.drawMenu("ZONES", visible, self.zoneIndex - startIndex + 1, 218, 20, 174)
        elseif self.menuMode == "confirm" then
            UIWindow.drawBox(96, 76, 208, 70)
            gfx.drawTextAligned("Generate a new zone?", 200, 88, kTextAlignment.center)
            gfx.drawTextAligned("A: yes     B: cancel", 200, 116, kTextAlignment.center)
        else
            UIWindow.drawMenu("MENU", self.menu, self.menuIndex, 224, 20, 168)
        end
    end
end
