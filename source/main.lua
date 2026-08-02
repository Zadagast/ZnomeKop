-- ZnomeKop
-- Sci-fi monster-collecting RPG on Mars (Playdate)
-- Vertical slice 0.1: procedural sectors + exploration

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

import "data/tiles"
import "data/generation"
import "data/creatures"
import "data/moves"

import "util/rng"
import "util/grid"

import "core/save"
import "core/state"
import "core/game"

import "ui/window"

import "world/mapgen"
import "world/world"
import "entities/player"

import "scenes/title"
import "scenes/explore"

local gfx = playdate.graphics

Game.boot()

function playdate.update()
    gfx.clear(gfx.kColorWhite)
    State.update()
    State.draw()
    playdate.timer.updateTimers()

    if playdate.isCrankDocked() == false then
        -- Optional: crank cycles seed preview on title in later polish.
    end
end

function playdate.gameWillTerminate()
    if Game.save and Game.save.seed then
        Save.write(Game.save)
    end
end

function playdate.deviceWillLock()
    if Game.save and Game.save.seed then
        Save.write(Game.save)
    end
end
