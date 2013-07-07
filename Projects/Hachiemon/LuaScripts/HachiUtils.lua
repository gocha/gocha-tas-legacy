--[[

 GBA Hachiemon Utility Script
 Operation check done by using vba-rr v23
 http://code.google.com/p/vba-rerecording/

 Contributer: gocha

 === Cheat Keys ===

 Level:
 up+select         Transform
 select            Select Transform
 down+select       Crush Ability (DANGEROUS)

]]--

-- option start here >>

local hachiRegularDebugFuncOn = true

local guiOpacity = 0.8

-- << options end here

-- [ generic utility functions ] -----------------------------------------------

if not emu then
    error("This script runs under vba-rr")
end

if not bit then
    require("bit")
end

-- [ gameemu lua utility functions ] -------------------------------------------

local pad_max = 1
local pad_press, pad_down, pad_up, pad_prev, pad_send = {}, {}, {}, {}, {}
local pad_presstime = {}
for player = 1, pad_max do
    pad_press[player] = {}
    pad_presstime[player] = { start=0, select=0, up=0, down=0, left=0, right=0, A=0, B=0, L=0, R=0 }
end

local dev_press, dev_down, dev_up, dev_prev = input.get(), {}, {}, {}
local dev_presstime = {
    xmouse=0, ymouse=0, leftclick=0, rightclick=0, middleclick=0,
    shift=0, control=0, alt=0, capslock=0, numlock=0, scrolllock=0,
    ["0"]=0, ["1"]=0, ["2"]=0, ["3"]=0, ["4"]=0, ["5"]=0, ["6"]=0, ["7"]=0, ["8"]=0, ["9"]=0,
    A=0, B=0, C=0, D=0, E=0, F=0, G=0, H=0, I=0, J=0, K=0, L=0, M=0, N=0, O=0, P=0, Q=0, R=0, S=0, T=0, U=0, V=0, W=0, X=0, Y=0, Z=0,
    F1=0, F2=0, F3=0, F4=0, F5=0, F6=0, F7=0, F8=0, F9=0, F10=0, F11=0, F12=0,
    F13=0, F14=0, F15=0, F16=0, F17=0, F18=0, F19=0, F20=0, F21=0, F22=0, F23=0, F24=0,
    backspace=0, tab=0, enter=0, pause=0, escape=0, space=0,
    pageup=0, pagedown=0, ["end"]=0, home=0, insert=0, delete=0,
    left=0, up=0, right=0, down=0,
    numpad0=0, numpad1=0, numpad2=0, numpad3=0, numpad4=0, numpad5=0, numpad6=0, numpad7=0, numpad8=0, numpad9=0,
    ["numpad*"]=0, ["numpad+"]=0, ["numpad-"]=0, ["numpad."]=0, ["numpad/"]=0,
    tilde=0, plus=0, minus=0, leftbracket=0, rightbracket=0,
    semicolon=0, quote=0, comma=0, period=0, slash=0, backslash=0
}

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
-- scan keyboard/mouse input
function scanInputDevs()
    dev_prev = copytable(dev_press)
    dev_press = input.get()
    -- scan keydowns, keyups
    dev_down = {}
    dev_up = {}
    for k in pairs(dev_presstime) do
        dev_down[k] = (dev_press[k] and not dev_prev[k])
        dev_up[k] = (dev_prev[k] and not dev_press[k])
    end
    -- count press length
    for k in pairs(dev_presstime) do
        if not dev_press[k] then
            dev_presstime[k] = 0
        else
            dev_presstime[k] = dev_presstime[k] + 1
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

local hachiTransformName = {
    "Normal",
    "Fire",
    "Invisible",
    "Mini",
    "Samurai",
    "Slime",
    "Angel",
    "Rolling",
    "Dolphin",
    "Penguin",
    "Mole",
    "Invincible"
}
local hachiTransformMax = 12
local hachiTransformSelect = 0
local hachiTransformStarter = 0x0b
local hachiTransformCrush = 0x0c

local hachiTransformRequested = nil
local hachiTransformStarted = false

--local RAM_gameMode = 0x7e0100
local RAM_transform = 0x030000c4

--local RAM_frozen = 0x7e13fb
--local RAM_paused = 0x7e13d4

--local gameMode_level = 20

local hachiPlayer = 1
local hachiGameModePrev, hachiGameMode, hachiGameModeChanged
local hachiPausePrev, hachiPause, hachiPauseChanged
local hachiTransform
-- scan some parameters that control behavior of the script
function hachiScanStatus()
    --hachiGameModePrev = hachiGameMode
    --hachiGameMode = memory.readbyte(RAM_gameMode)
    --hachiGameModeChanged = (hachiGameMode ~= hachiGameModePrev)
    --hachiPausePrev = hachiPause
    --hachiPause = (memory.readbyte(RAM_paused) ~= 0)
    --hachiPauseChanged = (hachiPause ~= hachiPausePrev)
    hachiPausePrev = false
    hachiPause = false
    hachiPauseChanged = false
    hachiTransform = memory.readbyte(RAM_transform)
end

-- request new transform
function hachiRequestTransform()
    if hachiTransformRequested ~= nil then
        return
    end

    hachiTransformRequested = hachiTransformSelect
    hachiTransformStarted = false
end

-- process transform request
function hachiProcessTransform()
    if hachiTransformRequested == nil then
        return
    end

    if not hachiTransformStarted then
        if hachiTransform ~= hachiTransformStarter then
            memory.writebyte(RAM_transform, hachiTransformStarter)
            hachiTransformStarted = true
        else
            memory.writebyte(RAM_transform, 0)
        end
    elseif hachiTransform ~= hachiTransformStarter then
        if hachiTransform ~= hachiTransformRequested then
            memory.writebyte(RAM_transform, hachiTransformRequested)
            memory.writebyte(RAM_transform+1, hachiTransformRequested)
            hachiTransformRequested = nil
        end
    end
end

-- [ game-specific main ] ------------------------------------------------------

-- apply various cheats that work in Level
function hachiApplyLevelCheats()
    if hachiRegularDebugFuncOn then
        -- transform
        if not hachiPause and pad_down[hachiPlayer].select then
            if pad_press[hachiPlayer].up then
                hachiRequestTransform()
            elseif pad_press[hachiPlayer].down then
                if hachiTransform < hachiTransformMax then
                    -- enable crush
                    memory.writebyte(RAM_transform, hachiTransformCrush)
                else
                    -- disable crush
                    memory.writebyte(RAM_transform, memory.readbyte(RAM_transform+1))
                end
            else
                hachiTransformSelect = (hachiTransformSelect + 1) % hachiTransformMax
            end
        end
        
        if memory.readword(0x03000d2a) == 269 then
            -- fart causes a miracle
            memory.writebyte(0x030000b0, 3) -- health
            memory.writebyte(0x030000b2, 0) -- lip quota
        end
    end

    hachiProcessTransform()
end

-- apply various cheats
function hachiApplyCheats()
    --if hachiGameMode == gameMode_level then
        hachiApplyLevelCheats()
    --end
end

-- display transform information
function hachiDrawTransformInfo()
    if not (smwGameMode == gameMode_level) then return end

    gui.opacity(guiOpacity)
    gui.text(0, 0, "TRANSFORM:" .. hachiTransformName[1 + hachiTransformSelect]:upper())
end

-- display some useful information
function hachiDisplayInfo()
    hachiDrawTransformInfo()
end

-- [ core ] --------------------------------------------------------------------

emu.registerbefore(function()
    scanJoypad()
    scanInputDevs()
    hachiScanStatus()
    --if not movie.active() then
       hachiApplyCheats()
       --sendJoypad()
    --end
end)

emu.registerafter(function()
end)

emu.registerexit(function()
    if not movie.active() then
        -- write memory undo routines
    end
end)

gui.register(function()
    hachiDisplayInfo()
end)
