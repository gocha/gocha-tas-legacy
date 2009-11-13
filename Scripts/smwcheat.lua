--[[

 Super Mario World (U) Cheat Script by gocha
 Operation check done by using snes9x-rr 1.43 v17 svn
 http://code.google.com/p/snes9x-rr/

 === Cheat Keys ===

 Level:
 up+select         Powerup (small,big,cape,fire)
 L+A               Change move method (normal.P-meter,free)
 pause+select      Exit the current level, with activating the next level
 pause+(A+select)  Exit the current level, with activating the next level (secret goal)
 pause+(B+select)  Exit the current level, without activating the next level

 Note: color blocks can't be activated if you beat a switch palace with the pause-exit cheat.

 === Other Features ===

 - P-meter display
 - Cut powerup / powerdown animation
 - Display some other useful informations (holding L+R in 0.5s may switch info view)

 Some of these features can be enabled / disabled by modifying the following option settings.

]]--

-- option start here >>

local smwCutPowerupAnimationOn = true
local smwCutPowerdownAnimationOn = true

local smwShowInfoMore = false -- if true, displays some of useful informations (hopefully)
local smwShowInfoMoreKeySw = false -- if true, holding L+R in 0.5s switches info view

-- Move speed definitions for free move mode.
-- I guess you usually won't need to modify these.
local smwFreeMoveSpeed = 2.0 -- px/f
local smwFreeMoveSpeedupMax = 4.0 -- px/f
local smwFreeMovePMeterLength = 1 -- frame(s)

-- << options end here

-- [ generic utility functions ] -----------------------------------------------

if not emu then
    error("This script runs under snes9x")
end

if not bit then
    require("bit")
end

-- [ gameemu lua utility functions ] -------------------------------------------

function gui.edgelessbox(x1, y1, x2, y2, colour)
    gui.line(x1+1, y1, x2-1, y1, colour) -- top
    gui.line(x2, y1+1, x2, y2-1, colour) -- right
    gui.line(x1+1, y2, x2-1, y2, colour) -- bottom
    gui.line(x1, y1+1, x1, y2-1, colour) -- left
end

local pad_max = 2
local pad_press, pad_down, pad_up, pad_prev, pad_send = {}, {}, {}, {}, {}
local pad_presstime = {}
for player = 1, pad_max do
    pad_press[player] = {}
    pad_presstime[player] = { start=0, select=0, up=0, down=0, left=0, right=0, A=0, B=0, X=0, Y=0, L=0, R=0 }
end

-- scan button presses
function scanJoypad()
    for i = 1, pad_max do
        pad_prev[i] = copytable(pad_press[i])
        pad_press[i] = joypad.get(i)
        pad_send[i] = copytable(pad_press[i])
        -- scan keydowns, keyups
        pad_down[i] = {}
        pad_up[i] = {}
        for k in pairs(pad_press[i]) do
            pad_down[i][k] = (pad_press[i][k] and not pad_prev[i][k])
            pad_up[i][k] = (pad_prev[i][k] and not pad_press[i][k])
        end
        -- count press length
        for k in pairs(pad_press[i]) do
            if not pad_press[i][k] then
                pad_presstime[i][k] = 0
            else
                pad_presstime[i][k] = pad_presstime[i][k] + 1
            end
        end
    end
end
-- send button presses
function sendJoypad()
    for i = 1, pad_max do
        joypad.set(i, pad_send[i])
    end
end

-- [ game-specific utility functions ] -----------------------------------------

local moveMethod_normal = 0
local moveMethod_pmeter = 1
local moveMethod_free = 2
local moveMethod_max = 3

local smwMoveMethod = moveMethod_normal
local smwFreeMovePMeter = 0

local RAM_frameCountAlt = 0x7e0014
local RAM_gameMode = 0x7e0100
local RAM_player = 0x7e0db3
local RAM_powerup = 0x7e0019
local RAM_pMeter = 0x7e13e4
local RAM_takeOffMeter = 0x7e149f
local RAM_starInvCount = 0x7e1490
local RAM_hurtInvCount = 0x7e1497
local RAM_xSpeed = 0x7e007b
local RAM_ySpeed = 0x7e007d
local RAM_xPos = 0x7e0094
local RAM_yPos = 0x7e0096
local RAM_xSubPos = 0x7e13da
local RAM_ySubPos = 0x7e13dc
local RAM_movement = 0x7e0071
local RAM_lockSpritesTimer = 0x7e009d
local RAM_marioFrameCount = 0x7e1496
local RAM_frozen = 0x7e13fb
local RAM_paused = 0x7e13d4
local RAM_levelIndex = 0x7e13bf
local RAM_levelFlagTable = 0x7e1ea2
local RAM_typeOfExit = 0x7e0dd5
local RAM_midwayPoint = 0x7e13ce
local RAM_activateNextLevel = 0x7e13ce

local pMeter_max = 112
local takeOffMeter_max = 112

local gameMode_ow  = 14
local gameMode_level = 20

local smwPlayerPrev, smwPlayer, smwPlayerChanged
local smwGameModePrev, smwGameMode, smwGameModeChanged
local smwPausePrev, smwPause, smwPauseChanged
local smwMovementPrev, smwMovement, smwMovementChanged
-- scan some parameters that control behavior of the script
function smwScanStatus()
    smwPlayerPrev = smwPlayer
    smwPlayer = memory.readbyte(RAM_player) + 1
    smwPlayerChanged = (smwPlayer ~= smwPlayerPrev)
    smwGameModePrev = smwGameMode
    smwGameMode = memory.readbyte(RAM_gameMode)
    smwGameModeChanged = (smwGameMode ~= smwGameModePrev)
    smwPausePrev = smwPause
    smwPause = (memory.readbyte(RAM_paused) ~= 0)
    smwPauseChanged = (smwPause ~= smwPausePrev)
    smwMovementPrev = smwMovement
    smwMovement = memory.readbyte(RAM_movement)
    smwMovementChanged = (smwMovement ~= smwMovementPrev)
end

-- increment powerup
function smwDoPowerUp()
    local powerup = memory.readbyte(RAM_powerup)
    memory.writebyte(RAM_powerup, (powerup + 1) % 4)
end

-- set move method
function smwSetMoveMethod(mode)
    -- cleanups
    if smwMoveMethod == moveMethod_free then
        memory.writebyte(RAM_frozen, 0) -- unfreeze Mario
    end
    -- apply new method
    smwMoveMethod = mode % moveMethod_max
end

-- normal move
function smwMoveNormalProc()
    -- do nothing
end

-- P-meter mode
function smwMovePMeterProc()
    memory.writebyte(RAM_pMeter, pMeter_max)
    memory.writebyte(RAM_takeOffMeter, takeOffMeter_max+1)
end

-- count own pmeter for 
function smwFreeMovePMeterCount()
    local move = pad_press[smwPlayer].left or pad_press[smwPlayer].right
        or pad_press[smwPlayer].up or pad_press[smwPlayer].down

    -- count up own P-meter
    if pad_press[smwPlayer].Y and move then
        if smwFreeMovePMeter < smwFreeMovePMeterLength then
            smwFreeMovePMeter = smwFreeMovePMeter + 1
        end
    else
        smwFreeMovePMeter = 0
    end
end

-- Free move mode
function smwMoveFreeProc()
    local x = memory.readword(RAM_xPos) + (memory.readbyte(RAM_xSubPos)/256.0)
    local y = memory.readword(RAM_yPos) + (memory.readbyte(RAM_ySubPos)/256.0)
    local speed, xv, yv = 0.0, 0.0, 0.0

    -- calc Mario's new position
    smwFreeMovePMeterCount()
    speed = smwFreeMoveSpeed + (smwFreeMoveSpeedupMax * smwFreeMovePMeter / smwFreeMovePMeterLength)
    if pad_press[smwPlayer].left  then xv = xv - speed end
    if pad_press[smwPlayer].right then xv = xv + speed end
    if pad_press[smwPlayer].up    then yv = yv - speed end
    if pad_press[smwPlayer].down  then yv = yv + speed end

    -- freeze Mario
    if smwMovement == 0 then
        memory.writebyte(RAM_frozen, 1)
        memory.writebyte(RAM_xSpeed, 0)
        memory.writebyte(RAM_ySpeed, 0)
        x, y = x + xv, y + yv

        -- but animate sprites
        memory.writebyte(RAM_frameCountAlt, (memory.readbyte(RAM_frameCountAlt) + 1) % 256)
    else
        memory.writebyte(RAM_frozen, 0)
    end
    -- make him invulnerable
    memory.writebyte(RAM_hurtInvCount, 127)
    -- manipulate Mario's position
    memory.writeword(RAM_xPos, math.floor(x))
    memory.writeword(RAM_yPos, math.floor(y))
    memory.writeword(RAM_xSubPos, math.floor(x*16)%16*16)
    memory.writeword(RAM_ySubPos, math.floor(y*16)%16*16)
end

local smwMoveMethodProc = { smwMoveNormalProc, smwMovePMeterProc, smwMoveFreeProc }

-- force allow escape
local smwForceSecretExit = false
local smwModExitStatus = false
function smwAllowEscape()
    if smwPause and pad_down[smwPlayer].select then
        local levelIndex = memory.readbyte(RAM_levelIndex)
        local levelFlag = memory.readbyte(RAM_levelFlagTable + levelIndex)
        -- save midway point flag
        if memory.readbyte(RAM_midwayPoint) == 1 then
            memory.writebyte(RAM_levelFlagTable + levelIndex, bit.bor(levelFlag, 0x40))
        end
        -- exit the level force
        memory.writebyte(RAM_levelFlagTable + levelIndex, bit.bor(levelFlag, 0x80))
        smwForceSecretExit = pad_press[smwPlayer].A
        -- activate next stage (destination must be written by smwRewriteOnPauseExit())
        -- pressing B will cancel this effect (exit without activate the next level)
        if not pad_press[smwPlayer].B then
            memory.writebyte(RAM_activateNextLevel, 1)
        else
            memory.writebyte(RAM_activateNextLevel, 0)
        end
        smwModExitStatus = true
    end
end

-- allow start+select to beat the level
function smwRewriteOnPauseExit()
    if not smwModExitStatus then return end
    if memory.readbyte(RAM_typeOfExit) == 0x80 and memory.readbyte(RAM_activateNextLevel) == 1 then
        if smwForceSecretExit then
            memory.writebyte(RAM_typeOfExit, 2)
        else
            memory.writebyte(RAM_typeOfExit, 1)
        end
        smwModExitStatus = false
    end
end

-- cut powerup animation
function smwCutPowerupAnimation()
    if smwMovement == 2 then -- super
        memory.writebyte(RAM_lockSpritesTimer, 0)
        memory.writebyte(RAM_movement, 0)
        memory.writebyte(RAM_marioFrameCount, 0)
        smwDoPowerUp() -- don't know why script needs to process it, anyway
    elseif smwMovement == 3 then -- cape
        memory.writebyte(RAM_lockSpritesTimer, 0)
        memory.writebyte(RAM_movement, 0)
        memory.writebyte(RAM_marioFrameCount, 0)
    elseif smwMovement == 4 then -- fire
        memory.writebyte(RAM_lockSpritesTimer, 0)
        memory.writebyte(RAM_movement, 0)
        memory.writebyte(RAM_marioFrameCount, 0)
        memory.writebyte(0x7e149b, 0)
    end
end

-- cut powerdown animation
function smwCutPowerdownAnimation()
    if smwMovement == 1 then -- powerdown
        memory.writebyte(RAM_lockSpritesTimer, 0)
        memory.writebyte(RAM_marioFrameCount, 0) -- stops 1 frame, but who cares
        -- memory.writebyte(RAM_movement, 0)
        -- memory.writebyte(RAM_hurtInvCount, 127)
    end
end

-- [ game-specific main ] ------------------------------------------------------

local preventItemPopup = false
-- apply various cheats that work in Level
function smwApplyLevelCheats()
    -- power-ups
    if not smwPause and pad_press[smwPlayer].up and pad_down[smwPlayer].select then
        smwDoPowerUp()
        preventItemPopup = true
    end
    -- moving method
    if not smwPause and pad_press[smwPlayer].L and not pad_press[smwPlayer].R and pad_down[smwPlayer].A then
        smwSetMoveMethod(smwMoveMethod + 1)
    end
    if not smwPause then
        smwMoveMethodProc[smwMoveMethod+1]()
    end

    -- prevent item popup
    if preventItemPopup and not pad_press[smwPlayer].select then
        preventItemPopup = false
    end
    if preventItemPopup then
        pad_send[smwPlayer].select = not pad_send[smwPlayer].select
    end

    -- cut powerup/powerdown animation
    if smwCutPowerupAnimationOn then
        smwCutPowerupAnimation()
    end
    if smwCutPowerdownAnimationOn then
        smwCutPowerdownAnimation()
    end

    -- allow escape
    smwAllowEscape()
end

-- apply various cheats
function smwApplyCheats()
    -- switch info display
    local pressLenLR = math.min(pad_presstime[smwPlayer].L, pad_presstime[smwPlayer].R)
    if smwShowInfoMoreKeySw and pressLenLR == 30 then
        smwShowInfoMore = not smwShowInfoMore
    end

    if smwGameMode == gameMode_level then
        smwApplyLevelCheats()
    elseif smwGameMode == gameMode_ow then
        smwMoveMethod = moveMethod_normal
    elseif smwGameMode == 11 then
        smwRewriteOnPauseExit()
    end
end

-- draw P-meter in the screen
local pMeterMaxCount = 0
function smwDrawPMeter()
    if not (smwGameMode == gameMode_level) then return end

    local pMeter = memory.readbyte(RAM_pMeter)
    local pMeterBarXPos = 8
    local pMeterBarYPos = 208
    local pMeterBarWidth = 112
    local pMeterBarHeight = 6
    local pMeterBarLen
    local pMeterBorderColor = "#000000ff"
    local pMeterMeterColorNormal = "#31bdc5cc"
    local pMeterMeterColorMax = { "#ff0000cc", "#ff0000cc", "#ffffffcc" }
    local pMeterMeterColor
    local pMeterBGColor = "#00000080"

    if pMeter >= pMeter_max or smwMoveMethod == moveMethod_pmeter then
        pMeterMaxCount = (pMeterMaxCount + 1) % 3
        pMeterMeterColor = pMeterMeterColorMax[1+pMeterMaxCount]
        pMeterBarLen = pMeterBarWidth
    else
        pMeterColorPulse = 0
        pMeterMeterColor = pMeterMeterColorNormal
        pMeterBarLen = math.floor((pMeter/1.0)*pMeterBarWidth/pMeter_max)
    end

    gui.edgelessbox(pMeterBarXPos, pMeterBarYPos, pMeterBarXPos + pMeterBarWidth, pMeterBarYPos + pMeterBarHeight, "#000000")
    gui.box(pMeterBarXPos + 1, pMeterBarYPos + 1, pMeterBarXPos + pMeterBarWidth - 1, pMeterBarYPos + pMeterBarHeight - 1, pMeterBGColor, pMeterBGColor)
    if pMeter > 0 then
        gui.box(pMeterBarXPos + 1, pMeterBarYPos + 1, pMeterBarXPos + pMeterBarLen - 1, pMeterBarYPos + pMeterBarHeight - 1, pMeterMeterColor, pMeterMeterColor)
    end
end

-- display some useful information
function smwDisplayInfo()

    smwDrawPMeter()

    if not smwShowInfoMore then return end

    if smwGameMode == gameMode_level then
        -- show Mario's position
        gui.text(120, 40, string.format("%4d.%03d,%3d.%03d",
            memory.readword(RAM_xPos), memory.readbyte(RAM_xSubPos),
            memory.readword(RAM_yPos), memory.readbyte(RAM_ySubPos)))
    end
end

-- [ core ] --------------------------------------------------------------------

emu.registerbefore(function()
    scanJoypad()
    smwScanStatus()
    if not movie.active() then
       if smwPlayer <= pad_max then
           smwApplyCheats()
       end
       sendJoypad()
    end
end)

emu.registerafter(function()
end)

emu.registerexit(function()
    if not movie.active() and smwMoveMethod == moveMethod_free then
        memory.writebyte(RAM_frozen, 0) -- unfreeze Mario
    end
end)

gui.register(function()
    smwDisplayInfo()
end)
