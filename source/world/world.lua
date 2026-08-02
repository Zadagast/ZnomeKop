-- World view: 32x32 tilemap + tall prop sprites (light 2.5D).

import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics

World = {}
World.__index = World

local TILE = 32
local SCREEN_W, SCREEN_H = 400, 240

-- buildings-table-96-64.png frame indices (96x64 = 3x2 tiles, door centered)
local BUILDING_FRAME = {
    [Tiles.OUTPOST] = 1,
    [Tiles.LAB] = 2,
    [Tiles.RUINS] = 3,
}

function World.new(map, player)
    local self = setmetatable({}, World)
    self.map = map
    self.player = player
    self.message = nil
    self.messageTimer = 0
    self.lastEncounterTile = nil
    self.props = {}
    self:buildTilemap()
    self:buildProps()
    return self
end

function World:buildTilemap()
    local tiles = self.map.tiles
    local imagetable = gfx.imagetable.new("images/tiles")
    assert(imagetable, "Missing images/tiles imagetable")

    local tilemap = gfx.tilemap.new()
    tilemap:setImageTable(imagetable)
    tilemap:setSize(tiles.width, tiles.height)
    tilemap:setTiles(tiles.data, tiles.width)

    self.tilemap = tilemap
    self.bgSprite = gfx.sprite.new()
    self.bgSprite:setTilemap(tilemap)
    self.bgSprite:setCenter(0, 0)
    self.bgSprite:moveTo(0, 0)
    self.bgSprite:setZIndex(-1000)
    self.bgSprite:add()
end

function World:buildProps()
    self.buildingImages = gfx.imagetable.new("images/buildings")
    assert(self.buildingImages, "Missing images/buildings imagetable")

    -- Door tile is the POI cell; the building spans 3 tiles wide x 2 tall,
    -- centered on the door column, extending one row up.
    local tiles = self.map.tiles
    for y = 1, tiles.height do
        for x = 1, tiles.width do
            local tile = Grid.get(tiles, x, y)
            local frame = BUILDING_FRAME[tile]
            if frame then
                local img = self.buildingImages:getImage(frame)
                local spr = gfx.sprite.new(img)
                spr:setCenter(0, 0)
                local px = (x - 2) * TILE
                local py = (y - 2) * TILE
                spr:moveTo(px, py)
                -- -1 so the player on the doorstep draws in front
                spr:setZIndex(1000 + y * TILE - 1)
                spr:add()
                self.props[#self.props + 1] = spr
            end
        end
    end
end

function World:tileAt(tx, ty)
    return Grid.get(self.map.tiles, tx, ty)
end

function World:canEnter(tx, ty)
    local tile = self:tileAt(tx, ty)
    return tile ~= nil and Tiles.isWalkable(tile)
end

function World:worldToScreen()
    local px = (self.player.tileX - 1) * TILE + self.player.offsetX + TILE / 2
    local py = (self.player.tileY - 1) * TILE + self.player.offsetY + TILE / 2
    local camX = math.floor(px - SCREEN_W / 2)
    local camY = math.floor(py - SCREEN_H / 2)

    local maxX = self.map.width * TILE - SCREEN_W
    local maxY = self.map.height * TILE - SCREEN_H
    if maxX < 0 then maxX = 0 end
    if maxY < 0 then maxY = 0 end
    if camX < 0 then camX = 0 elseif camX > maxX then camX = maxX end
    if camY < 0 then camY = 0 elseif camY > maxY then camY = maxY end

    gfx.setDrawOffset(-camX, -camY)
    self.cameraX = camX
    self.cameraY = camY
end

function World:showMessage(text, frames)
    self.message = text
    self.messageTimer = frames or 100
end

function World:interact()
    local tile = self:tileAt(self.player.tileX, self.player.tileY)
    local info = Tiles.Info[tile]
    if info and info.poi then
        if info.poiType == "outpost" then
            self:showMessage("OUTPOST\nLink online. Your party was restocked.")
            if Game and Game.healParty then
                Game.healParty()
            end
        elseif info.poiType == "lab" then
            self:showMessage("RESEARCH LAB\nScanners ready. Collection synced.")
        elseif info.poiType == "tube" then
            self:showMessage("LAVA TUBE\nA dark descent. Deeper layers soon.")
        elseif info.poiType == "ruins" then
            self:showMessage("RUINS\nOld transmitters still whisper...")
        else
            self:showMessage(info.name)
        end
        return
    end
    if tile == Tiles.ENCOUNTER then
        self:showMessage("DUSTREED\nSignals flicker in the stalks.")
        return
    end
    self:showMessage(Tiles.displayName(tile))
end

function World:rollEncounter()
    local tx, ty = self.player.tileX, self.player.tileY
    local key = tx .. ":" .. ty
    if self.lastEncounterTile == key then
        return
    end
    self.lastEncounterTile = key

    local tile = self:tileAt(tx, ty)
    local chance = Tiles.encounterChance(tile)
    if chance <= 0 then
        return
    end
    if Game.rng:chance(chance) then
        local habitat = "rock"
        if tile == Tiles.ENCOUNTER then
            habitat = "signal"
        elseif Tiles.isDust(tile) then
            habitat = "dust"
        elseif tile == Tiles.CANYON then
            habitat = "canyon"
        elseif tile == Tiles.RUINS then
            habitat = "ruins"
        elseif tile == Tiles.CRATER then
            habitat = "crater"
        end
        local creature = Creatures.pickForHabitat(habitat, Game.rng)
        Game.save.stats.encounters += 1
        self:showMessage("Wild " .. creature.name .. " appeared!\n(Battle systems coming next.)", 140)
    end
end

function World:update()
    self.player:update(self)

    if self.player.justStepped then
        Game.save.stats.steps += 1
        Game.save.playerX = self.player.tileX
        Game.save.playerY = self.player.tileY
        self:rollEncounter()
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        self:interact()
    end

    if self.messageTimer > 0 then
        self.messageTimer -= 1
        if self.messageTimer <= 0 then
            self.message = nil
        end
    end
end

function World:drawHud()
    gfx.setDrawOffset(0, 0)

    local tile = self:tileAt(self.player.tileX, self.player.tileY)
    local name = Tiles.displayName(tile)
    local chipW = #name * 8 + 20
    if chipW < 84 then chipW = 84 end
    UIWindow.drawBox(6, 6, chipW, 24)
    gfx.drawText(name, 14, 11)

    if self.message then
        UIWindow.drawMessage(self.message)
    end
end

function World:draw()
    self:worldToScreen()
    gfx.sprite.update()
    self:drawHud()
end

function World:destroy()
    if self.bgSprite then
        self.bgSprite:remove()
        self.bgSprite = nil
    end
    for i = 1, #self.props do
        self.props[i]:remove()
    end
    self.props = {}
    if self.player and self.player.sprite then
        self.player.sprite:remove()
    end
    gfx.setDrawOffset(0, 0)
end
