-- Grid explorer: 32x32 sprite, walk frames, Y-sorted depth.

import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx = playdate.graphics

local TILE = 32
local STEP_FRAMES = 8

Player = {}
Player.__index = Player

-- imagetable holds three poses per facing: neutral, step-left, step-right
local NEUTRAL, STEP_A, STEP_B = 1, 2, 3

local FRAME = {
    down = { 1, 2, 3 },
    up = { 4, 5, 6 },
    left = { 7, 8, 9 },
    right = { 10, 11, 12 },
}

function Player.new(tileX, tileY)
    local self = setmetatable({}, Player)
    self.tileX = tileX
    self.tileY = tileY
    self.offsetX = 0
    self.offsetY = 0
    self.facing = "down"
    self.moving = false
    self.moveTime = 0
    self.fromX, self.fromY = 0, 0
    self.toX, self.toY = 0, 0
    self.justStepped = false
    self.stepParity = 0

    self.images = gfx.imagetable.new("images/player")
    assert(self.images, "Missing images/player imagetable")

    self.sprite = gfx.sprite.new(self.images:getImage(FRAME.down[NEUTRAL]))
    self.sprite:setCenter(0.5, 1.0) -- feet anchored for 2.5D sorting
    self:syncSprite()
    self.sprite:add()
    return self
end

function Player:currentFrame()
    local frames = FRAME[self.facing]
    if not self.moving then
        return frames[NEUTRAL]
    end
    -- Alternate feet per tile stepped, and pass through neutral at the
    -- midpoint of each step so the gait has a contact-passing rhythm.
    if self.moveTime * 2 < STEP_FRAMES then
        return frames[(self.stepParity % 2 == 0) and STEP_A or STEP_B]
    end
    return frames[NEUTRAL]
end

function Player:syncSprite()
    local px = (self.tileX - 1) * TILE + self.offsetX + TILE / 2
    local py = (self.tileY - 1) * TILE + self.offsetY + TILE
    self.sprite:moveTo(px, py)
    self.sprite:setImage(self.images:getImage(self:currentFrame()))
    -- Higher Y draws in front (classic 2.5D)
    self.sprite:setZIndex(1000 + math.floor(py))
end

function Player:tryStep(world, dx, dy, facing)
    if self.moving then
        return
    end
    self.facing = facing
    local nx = self.tileX + dx
    local ny = self.tileY + dy
    if not world:canEnter(nx, ny) then
        self:syncSprite()
        return
    end
    self.moving = true
    self.moveTime = 0
    self.fromX, self.fromY = 0, 0
    self.toX, self.toY = dx * TILE, dy * TILE
    self.nextTileX = nx
    self.nextTileY = ny
end

function Player:handleInput(world)
    if self.moving then
        return
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        self:tryStep(world, 0, -1, "up")
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        self:tryStep(world, 0, 1, "down")
    elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
        self:tryStep(world, -1, 0, "left")
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        self:tryStep(world, 1, 0, "right")
    end
end

function Player:update(world)
    self.justStepped = false
    self:handleInput(world)

    if self.moving then
        self.moveTime += 1
        local t = self.moveTime / STEP_FRAMES
        if t >= 1 then
            self.tileX = self.nextTileX
            self.tileY = self.nextTileY
            self.offsetX = 0
            self.offsetY = 0
            self.moving = false
            self.justStepped = true
            self.stepParity += 1
        else
            self.offsetX = self.fromX + (self.toX - self.fromX) * t
            self.offsetY = self.fromY + (self.toY - self.fromY) * t
        end
    end

    self:syncSprite()
end
