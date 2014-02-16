--[[
 
 SNES Madou Monogatari - Hanamaru Daiyouchienji
 Extra Status Display
 written by gocha for snes9x-rr 1.43 v17 svn.
 
]]--

-- common
local guiOpacityLevel = 1.0
local skipStatusAnimation = false
local detailedWeaknessInfo = false

-- [ startup ] -----------------------------------------------------------------

emu = emu or snes9x
if not emu then error("Unknown SNES EmuLua host.") end

if not bit then
	require("bit")
end

-- Instant ROM check
function romCheck()
	if string.char(unpack(memory.readbyterange(0x80ffb2, 4))) ~= "ADYJ" then
		return false
	end
	return true
end
if not romCheck() then
	error("Unsupported ROM: make sure if the current ROM is Madou Monogatari")
end

-- [ ROM/RAM addresses ] -------------------------------------------------------

local RAM = {
	fadeLevel = 0x7e0c5b,         -- screen fade level
	pauseFlag = 0x7e0266,         -- becomes 1 when the game is paused
	overworldFlag = 0x7e0980,     -- becomes 1 when the game is overworld map
	battleFieldFlag = 0x7e0263,   -- becomes 1 during a battle/pause (incorrect a little)
	statusScreenFlag = 0x7e1d61,  -- becomes 1 during showing the status screen
	menubarScroll = 0x7e1739,     -- becomes 72 when the bottom menu completely appeared (alternative: 0x7e02c8)
	ItemScreenFlag = 0x7e00be,    -- becomes 11 (from 10) when the game shows Arle's equipped rod/ring box
	arleXPosW = 0x7e4827, arleYPosW = 0x7e4829,
	bgXPosW = 0x7e16e2, bgYPosW = 0x7e16e6,
	frames = 0x7e1300, minutes = 0x7e1302, -- ingame timer
	menuCursorPos = 0x7e1678,     -- alternative: 0x7e167c
	menuLastSelect = 0x7e13b8,
	arleStatBase = 0x7e1345, enemyStatBase = 0x7e17be,
	randomness = 0x7e00b2,
	encounter = 0x7e1408
}

local BtStatIndex = {
	level = 0, hp = 1, mp = 3, atk = 5, def = 6, spd = 7, mdef = 8,
	fireDef = 9, iceDef = 10, thunderDef = 11, a0c = 12, a0d = 13,
	hpMax = 14, mpMax = 16, diacuteLevel = 18, fireLevel = 19,
	iceLevel = 20, thunderLevel = 21, healLevel = 22, boss = 23
}

-- [ utility functions ] -------------------------------------------------------

-- xx seconds => h:mm:ss.ss
function formatseconds(seconds)
    local h, m, s
    s = seconds % 60
    m = math.floor(seconds / 60)
    h = math.floor(m / 60)
    m = m % 60
    return string.format("%d:%02d:%05.2f", h, m, s)
end

-- Lua version of win32 PtInRect
function ptInRect(rect, pt)
	if pt.x >= rect.left and pt.x <= rect.right and pt.y >= rect.top and pt.y <= rect.bottom then
		return true
	else
		return false
	end
end

local allkeys = {
	shift = 1, control = 1, alt = 1, capslock = 1, numlock = 1, scrolllock = 1,
	["0"] = 1, ["1"] = 1, ["2"] = 1, ["3"] = 1, ["4"] = 1, ["5"] = 1, ["6"] = 1, ["7"] = 1, ["8"] = 1, ["9"] = 1,
	A = 1, B = 1, C = 1, D = 1, E = 1, F = 1, G = 1, H = 1, I = 1, J = 1, K = 1, L = 1, M = 1, N = 1, O = 1, P = 1, Q = 1, R = 1, S = 1, T = 1, U = 1, V = 1, W = 1, X = 1, Y = 1, Z = 1,
	F1 = 1, F2 = 1, F3 = 1, F4 = 1, F5 = 1, F6 = 1, F7 = 1, F8 = 1, F9 = 1, F10 = 1, F11 = 1, F12 = 1,
	F13 = 1, F14 = 1, F15 = 1, F16 = 1, F17 = 1, F18 = 1, F19 = 1, F20 = 1, F21 = 1, F22 = 1, F23 = 1, F24 = 1,
	backspace = 1, tab = 1, enter = 1, pause = 1, escape = 1, space = 1,
	pageup = 1, pagedown = 1, ["end"] = 1, home = 1, insert = 1, delete = 1,
	left = 1, up = 1, right = 1, down = 1,
	numpad0 = 1, numpad1 = 1, numpad2 = 1, numpad3 = 1, numpad4 = 1, numpad5 = 1, numpad6 = 1, numpad7 = 1, numpad8 = 1, numpad9 = 1,
	["numpad*"] = 1, ["numpad+"] = 1, ["numpad-"] = 1, ["numpad."] = 1, ["numpad/"] = 1,
	tilde = 1, plus = 1, minus = 1, leftbracket = 1, rightbracket = 1,
	semicolon = 1, quote = 1, comma = 1, period = 1, slash = 1, backslash = 1,
	leftclick = 1, rightclick = 1, middleclick = 1
}
local allpads = { left = 1, up = 1, right = 1, down = 1, A = 1, B = 1, X = 1, Y = 1, L = 1, R = 1, start = 1, select = 1 }

local pad, padOld = {}, {}
local padDown, padUp = {}, {}
local padTime = {}
local key, keyOld = {}, {}
local keyDown, keyUp = {}, {}
local keyTime = {}
local mouse, mouseOld = {}, {}
for k in pairs(allpads) do padTime[k] = 0 end
for k in pairs(allkeys) do keyTime[k] = 0 end

function emuluaKeyInputUpdate()
	key = input.get()
	mouse = { x = key.xmouse, y = key.ymouse }
	-- triggered input
	key.xmouse, key.ymouse = nil, nil
	keyDown, keyUp = {}, {}
	for k in pairs(allkeys) do
		if key[k] then
			if not keyOld[k] then keyDown[k] = 1 end
			keyTime[k] = keyTime[k] + 1
		else
			if keyOld[k] then keyUp[k] = 1 end
			keyTime[k] = 0
		end
	end

	pad = joypad.get(1)
	padDown, padUp = {}, {}
	for k in pairs(allpads) do
		if pad[k] then
			if not padOld[k] then padDown[k] = 1 end
			padTime[k] = padTime[k] + 1
		else
			if padOld[k] then padUp[k] = 1 end
			padTime[k] = 0
		end
	end
	padOld = pad
end

function emuluaKeyInputUpdateAfter()
	keyOld = key
	mouseOld = mouse
end

function gui.roundedbox(x1, y1, x2, y2, colour)
	gui.line(x1+1, y1, x2-1, y1, colour) -- top
	gui.line(x2, y1+1, x2, y2-1, colour) -- right
	gui.line(x1+1, y2, x2-1, y2, colour) -- bottom
	gui.line(x1, y1+1, x1, y2-1, colour) -- left
end

-- [ core routines ] -----------------------------------------------------------

local arleStatDisp = { hpRate = 1.0 }
local enemyStatDisp = { hpRate = 1.0 }
local hpGaugeLen = 81

local arlePrevLevel
local arlePrevHPMax, arlePrevMPMax
local arlePrevATK, arlePrevDEF, arlePrevSPD
local arlePrevMDEF, arlePrevA0C, arlePrevA0D
local levelUpStatShowCount, levelUpStatShowLength = 0, 180

function screenFadeLevel()
	local fadeLevel = memory.readbyte(RAM.fadeLevel)
	if fadeLevel > 15 then fadeLevel = 0 end
	return fadeLevel
end

function updateBattleStatFast()
	local update = function(base, stat)
		local hp = memory.readword(base + BtStatIndex.hp)
		local hpMax = memory.readword(base + BtStatIndex.hpMax)
		local mp = memory.readword(base + BtStatIndex.mp)
		local mpMax = memory.readword(base + BtStatIndex.mpMax)

		stat.hpRate = hp / hpMax
		stat.mpRate = (mpMax ~= 0 and mp / mpMax or 0)
	end
	update(RAM.arleStatBase, arleStatDisp)
	update(RAM.enemyStatBase, enemyStatDisp)
end

function updateBattleStatSlow()
	if skipStatusAnimation then
		updateBattleStatFast()
		return
	end

	local update = function(base, stat)
		local hp = memory.readword(base + BtStatIndex.hp)
		local hpMax = memory.readword(base + BtStatIndex.hpMax)
		local hpRate = hp / hpMax
		local mp = memory.readword(base + BtStatIndex.mp)
		local mpMax = memory.readword(base + BtStatIndex.mpMax)
		local mpRate = (mpMax ~= 0 and mp / mpMax or 0)

		local delta = math.min(1.0/hpMax, 1.0/hpGaugeLen)
		if stat.hpRate < hpRate then
			stat.hpRate = stat.hpRate + delta
			if stat.hpRate > hpRate then
				stat.hpRate = hpRate
			end
		elseif stat.hpRate > hpRate then
			stat.hpRate = stat.hpRate - delta
			if stat.hpRate < hpRate then
				stat.hpRate = hpRate
			end
		end

		local delta = math.min(1.0/mpMax, 1.0/hpGaugeLen)
		if stat.mpRate < mpRate then
			stat.mpRate = stat.mpRate + delta
			if stat.mpRate > mpRate then
				stat.mpRate = mpRate
			end
		elseif stat.mpRate > mpRate then
			stat.mpRate = stat.mpRate - delta
			if stat.mpRate < mpRate then
				stat.mpRate = mpRate
			end
		end
	end
	update(RAM.arleStatBase, arleStatDisp)
	update(RAM.enemyStatBase, enemyStatDisp)
end

function updateLevelStatFast()
	levelUpStatShowCount = 0
	arlePrevLevel = memory.readbyte(RAM.arleStatBase + BtStatIndex.level)
	arlePrevHPMax = memory.readword(RAM.arleStatBase + BtStatIndex.hpMax)
	arlePrevMPMax = memory.readword(RAM.arleStatBase + BtStatIndex.mpMax)
	arlePrevATK = memory.readbyte(RAM.arleStatBase + BtStatIndex.atk)
	arlePrevDEF = memory.readbyte(RAM.arleStatBase + BtStatIndex.def)
	arlePrevSPD = memory.readbyte(RAM.arleStatBase + BtStatIndex.spd)
	arlePrevMDEF = memory.readbyte(RAM.arleStatBase + BtStatIndex.mdef)
	arlePrevA0C = memory.readbyte(RAM.arleStatBase + BtStatIndex.a0c)
	arlePrevA0D = memory.readbyte(RAM.arleStatBase + BtStatIndex.a0d)
end

function isDuringBattle()
	return memory.readbyte(RAM.battleFieldFlag) == 1 and memory.readbyte(0x7e0c2a) == 1
end

function isStatusView()
	return memory.readbyte(RAM.statusScreenFlag) == 1
end

function isConfigScreen()
	return memory.readbyte(RAM.statusScreenFlag) ~= 1 and memory.readbyte(0x7e0343) == 1
end

function isItemSelectOW()
	return memory.readbyte(RAM.battleFieldFlag) == 1 and memory.readbyte(RAM.menuLastSelect) == 1 and memory.readbyte(0x7e0a4b) == 184
end

function isBattleStatVisible()
	local fadeLevel = screenFadeLevel()
	if memory.readbyte(RAM.battleFieldFlag) ~= 1 then
		return false
	end
	return not isStatusView() and fadeLevel >= 1 and not isConfigScreen()
end

local guiTextColor = "#ffffff80"
local guiEmTextColor = "#ff0000"
function gui.drawgauge(gaugeInfo, leftLabel, rightLabel, textColor, textOutlineColor)
	if not gaugeInfo.height then gaugeInfo.height = 2 end
	if not gaugeInfo.color then gaugeInfo.color = "#de0000" end
	if not gaugeInfo.bgcolor then gaugeInfo.bgcolor = "#00000080" end
	if not gaugeInfo.borderColor then gaugeInfo.borderColor = "#000000e0" end
	if not textColor then textColor = guiTextColor end
	if not textOutlineColor then textOutlineColor = "#000000" end

	local x, y = gaugeInfo.x, gaugeInfo.y
	gui.roundedbox(x, y, x + 2 + gaugeInfo.width, y + 2 + gaugeInfo.height, gaugeInfo.borderColor)
	gui.box(x + 1, y + 1, x + 1 + gaugeInfo.width, y + 1 + gaugeInfo.height, gaugeInfo.bgcolor, gaugeInfo.bgcolor)
	if gaugeInfo.rate > 0 then
		gui.box(x + 1, y + 1, x + 1 + (gaugeInfo.width * gaugeInfo.rate), y + 1 + gaugeInfo.height, gaugeInfo.color, gaugeInfo.color)
	end
	if leftLabel then
		gui.text(x - 1 - (#leftLabel * 4), y - (gaugeInfo.height/2), leftLabel, textColor, textOutlineColor)
	end
	if rightLabel then
		gui.text(x + gaugeInfo.width + 6, y - (gaugeInfo.height/2), rightLabel, textColor, textOutlineColor)
	end
end

function drawHPGauge(x, y, hp, hpMax, leftLabel)
	if not leftLabel then leftLabel = "HP" end

	local gaugeColors = { "#de0000", "#d62900", "#ce5200", "#c68400", "#948c00", "#639400", "#319c00", "#00ad00" }
	local hpRank = 8 - math.ceil(8*math.floor(hp)/hpMax)
	if hpRank > 7 then hpRank = 7 end
	local gaugeColor = gaugeColors[8 - hpRank]

	gui.drawgauge({ x = x, y = y, width = hpGaugeLen, rate = hp/hpMax, color = gaugeColor }, leftLabel, string.format("%3d/%3d", hp, hpMax))
end

function drawMPGauge(x, y, mp, mpMax, leftLabel)
	if not leftLabel then leftLabel = "MP" end

	local gaugeColors = { "#5a5a5a", "#4a5a63", "#396373", "#316b84", "#216b94", "#1873a5", "#087bb5", "#0084c6" }
	local mpRank = 8 - math.ceil(8*math.floor(mp)/mpMax)
	if mpRank > 7 then mpRank = 7 end
	local gaugeColor = gaugeColors[8 - mpRank]

	gui.drawgauge({ x = x, y = y, width = hpGaugeLen, rate = mp/mpMax, color = gaugeColor }, leftLabel, string.format("%3d/%3d", mp, mpMax))
end

function guiBattleStatDisplay()
	local fadeLevel = screenFadeLevel()

	local draw = function(x, y, base, stat)
		gui.opacity((0.88 * guiOpacityLevel) * fadeLevel / 15.0)

		local level = memory.readbyte(base + BtStatIndex.level)
		local hp = memory.readword(base + BtStatIndex.hp)
		local hpMax = memory.readword(base + BtStatIndex.hpMax)
		local assumedHP = stat.hpRate * hpMax
		local mp = memory.readword(base + BtStatIndex.mp)
		local mpMax = memory.readword(base + BtStatIndex.mpMax)
		local assumedMP = stat.mpRate * mpMax
		local atk = memory.readbyte(base + BtStatIndex.atk)
		local def = memory.readbyte(base + BtStatIndex.def)
		local spd = memory.readbyte(base + BtStatIndex.spd)
		local mdef = memory.readbyte(base + BtStatIndex.mdef)
		local fireDef = memory.readbyte(base + BtStatIndex.fireDef)
		local iceDef = memory.readbyte(base + BtStatIndex.iceDef)
		local thunderDef = memory.readbyte(base + BtStatIndex.thunderDef)
		local a0c = memory.readbyte(base + BtStatIndex.a0c)
		local a0d = memory.readbyte(base + BtStatIndex.a0d)
		local fireLevel = memory.readbyte(base + BtStatIndex.fireLevel)
		local iceLevel = memory.readbyte(base + BtStatIndex.iceLevel)
		local thunderLevel = memory.readbyte(base + BtStatIndex.thunderLevel)
		local healLevel = memory.readbyte(base + BtStatIndex.healLevel)

		if isDuringBattle() then
			gui.text(x + 2, y - 1, string.format("LV.%02d", level), guiTextColor)
			y = y + 7
		end
		drawHPGauge(x, y, assumedHP, hpMax)
		y = y + 7
		drawMPGauge(x, y, assumedMP, mpMax, "MP")
		y = y + 7
		if isDuringBattle() then
			gui.text(x - 5, y, string.format(" ATK:%3d  DEF:%3d  SPD:%3d", atk, def, spd), guiTextColor)
			y = y + 8
			gui.text(x - 5, y, string.format("MDEF:%3d PRM1:%3d PRM2:%3d", mdef, a0c, a0d), guiTextColor)
			y = y + 8
			if not (fireLevel == 1 and iceLevel == 1 and thunderLevel == 1 and healLevel == 0) then
				gui.text(x - 5, y, string.format("FI/IC/TN/HL LEVEL: %d %d %d %d", fireLevel, iceLevel, thunderLevel, healLevel), guiTextColor)
				y = y + 8
			end
			if fireDef ~= iceDef or fireDef ~= thunderDef then
				if detailedWeaknessInfo then
					local lowestDef = math.min(fireDef, math.min(iceDef, thunderDef))
					gui.text(x - 5, y, "FI/IC/TN DEFS: ", guiTextColor)
					gui.text(x - 5 + 60, y, string.format("%3d", fireDef), (fireDef == lowestDef and guiEmTextColor or guiTextColor))
					gui.text(x - 5 + 76, y, string.format("%3d", iceDef), (iceDef == lowestDef and guiEmTextColor or guiTextColor))
					gui.text(x - 5 + 92, y, string.format("%3d", thunderDef), (thunderDef == lowestDef and guiEmTextColor or guiTextColor))
				else
					local weakSpell = ""
					local separator = " "
					if fireDef <= math.min(iceDef, thunderDef) then
						if weakSpell ~= "" then weakSpell = weakSpell .. separator end
						weakSpell = weakSpell .. "FIRE"
					end
					if iceDef <= math.min(fireDef, thunderDef) then
						if weakSpell ~= "" then weakSpell = weakSpell .. separator end
						weakSpell = weakSpell .. "ICE"
					end
					if thunderDef <= math.min(fireDef, iceDef) then
						if weakSpell ~= "" then weakSpell = weakSpell .. separator end
						weakSpell = weakSpell .. "THUNDER"
					end
					gui.text(x - 5, y, "WEAKNESS: " .. weakSpell, guiTextColor)
				end
				y = y + 8
			end
		end
	end
	if isItemSelectOW() then
		draw(12, 2, RAM.arleStatBase, arleStatDisp)
	else
		draw(12, 2, RAM.arleStatBase, arleStatDisp)
	end
	if isDuringBattle() then
		draw(140, 2, RAM.enemyStatBase, enemyStatDisp)
	end
end

function guiCommonInfoDisplay()
	local fadeLevel = screenFadeLevel()

	gui.opacity((0.68 * guiOpacityLevel) * (fadeLevel / 30.0 + 0.5))

	local totalFrames = (3600 * memory.readword(RAM.minutes)) + memory.readword(RAM.frames)
	local ingameTime = formatseconds(totalFrames/60.0)
	--gui.text(128 - (#ingameTime * 2), 1, ingameTime)
	--gui.text(255 - (#ingameTime * 4), 1, ingameTime)
	gui.box(255 - (#ingameTime * 4) - 2, 215 - 1, 255, 223, "#000000e0", "#000000e0")
	gui.text(255 - (#ingameTime * 4), 215, ingameTime)

	if levelUpStatShowCount > 0 then
		local level = memory.readbyte(RAM.arleStatBase + BtStatIndex.level)
		local hpDiff = memory.readword(RAM.arleStatBase + BtStatIndex.hpMax) - arlePrevHPMax
		local mpDiff = memory.readword(RAM.arleStatBase + BtStatIndex.mpMax) - arlePrevMPMax
		local atkDiff = memory.readbyte(RAM.arleStatBase + BtStatIndex.atk) - arlePrevATK
		local defDiff = memory.readbyte(RAM.arleStatBase + BtStatIndex.def) - arlePrevDEF
		local spdDiff = memory.readbyte(RAM.arleStatBase + BtStatIndex.spd) - arlePrevSPD
		local mdefDiff = memory.readbyte(RAM.arleStatBase + BtStatIndex.mdef) - arlePrevMDEF
		local a0cDiff = memory.readbyte(RAM.arleStatBase + BtStatIndex.a0c) - arlePrevA0C
		local a0dDiff = memory.readbyte(RAM.arleStatBase + BtStatIndex.a0d) - arlePrevA0D
		local ownFade = 15

		if not skipStatusAnimation then
			ownFade = math.max(0, levelUpStatShowLength - levelUpStatShowCount)
			if ownFade > 15 then
				ownFade = math.min(15, levelUpStatShowCount)
			end
		end

		gui.opacity((0.68 * guiOpacityLevel) * fadeLevel / 15.0 * ownFade / 15.0)

		gui.box(54, 8, 54+148, 8+16, "#00000080", "#00000080")
		gui.text(54, 8, string.format([[
LV.%2d: HP +%2d MP   +%1d ATK  +%1d DEF  +%1d
       SPD +%1d MDEF +%1d PRM1 +%1d PRM2 +%1d]], level, hpDiff, mpDiff, atkDiff, defDiff, spdDiff, mdefDiff, a0cDiff, a0dDiff))
	end
end

-- [ main routines ] -----------------------------------------------------------

savestate.registerload( function()
	updateBattleStatFast()
	updateLevelStatFast()
end)

emu.registerexit( function()
	emu.registerbefore(nil)
	emu.registerafter(nil)
	savestate.registerload(nil)
	gui.register(nil)
end)

emu.registerbefore( function()
	emuluaKeyInputUpdate()
	if isBattleStatVisible() then
		updateBattleStatSlow()
	else
		updateBattleStatFast()
	end
end)

emu.registerafter( function()
	emuluaKeyInputUpdateAfter()

	-- detect levelup
	if arlePrevLevel ~= memory.readbyte(RAM.arleStatBase + BtStatIndex.level) then
		levelUpStatShowCount = levelUpStatShowLength
	end
	arlePrevLevel = memory.readbyte(RAM.arleStatBase + BtStatIndex.level)

	if levelUpStatShowCount > 15 and memory.readbyte(RAM.overworldFlag) ~= 1 then
		levelUpStatShowCount = 15
	elseif levelUpStatShowCount > 0 then
		levelUpStatShowCount = levelUpStatShowCount - 1
	end
end)

gui.register( function()
	guiCommonInfoDisplay()
	if isBattleStatVisible() then
		guiBattleStatDisplay()
	end
end)

updateBattleStatFast()
updateLevelStatFast()
--[[
while true do
	if not romCheck() then
		emu.registerbefore(nil)
		emu.registerafter(nil)
		emu.registerexit(nil)
		gui.register(nil)
		--emu.message("Script closed.")
		break
	end
	emu.frameadvance()
end
]]
