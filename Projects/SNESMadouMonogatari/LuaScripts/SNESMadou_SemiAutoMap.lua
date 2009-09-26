--[[
 
 SNES Madou Monogatari - Hanamaru Daiyouchienji
 Semi-Automated Map Maker (with drag and drop)
 written by gocha for snes9x-rr 1.43 v16.
 
 This script allows you to take a kindergartener girl to anywhere you like.
 Also, you can take a picture there instantly. Fuzzy pickles!
 
 As usual, the source code is extremely messy. It's awful :(
 Anyway, it can be redistributed and/or modified freely. Cleanups are welcome :P
 
 = Features =
 
   * Left-click: can drag Arle to anywhere you like.
   * Right-click: can summon Arle to where the mouse-pointer is.
   * (joypad) B+X: can switch the encounter killer on/off.
   * (joypad) X: start/abort the map capture.
 
 = How The Semi-Automated Map Capture Works =
 
   1. Save the game state first, and prepare necessary things (ex. a big gd canvas for the room map)
   2. Move Arle to the certain target position
   3. Pause and unpause game to refresh the game screen
   4. Take a screenshot and paste it to a big canvas
   5. Load the savestate which is created at the start of capture,
      then repeat that capture from 2. until the map will be completed.
   6. Output the final product, now the capture is done!
 
]]--

-- common
local guiOpacityMax = 0.68

-- map capture
local imageFileName = "semiautomap.png"
local manualCapture = false -- if true, you can decide capture timing by pressing 'start' button
local roomInfoInMapImage = false
local noConfirm = false
local pngCompressLevel = -1
local jpegQuality = 60

-- free move
local avoidEncounters = true -- can be switched with B+X
local drawCursor = false -- true to record the cursor in avi
local noScrollAreaSize = 24
local scrollSpeedScale = 0.5
local scrollSpeedMax = 32

-- Usually, you don't need to adjust the following size, but if the script
-- didn't work properly because of something which begins a dialog,
-- decrease the size and try to avoid it (I don't know if it will succeed though).
-- The size is originally 256x159, but it must be the multiple of 8.
-- Therefore, if you have no problem, just set it to 256x152 (152=8*19).
local imagePieceSize = { x = 256, y = 8*19 }

-- [ startup ] -----------------------------------------------------------------

if emu then error("Unknown SNES EmuLua host.") end
emu = snes9x
if not emu then error("Unknown SNES EmuLua host.") end

-- require("bit")
local bit = {}
bit.band = AND
bit.bor  = OR
bit.bxor = XOR
function bit.lshift(num, shift) return SHIFT(num, -shift) end
function bit.rshift(num, shift) return SHIFT(num,  shift) end

require("gd")

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

local capturingMap = false
local mapCaptLoadingState = false
local savMapCaptStart = savestate.create()
local renderedWithoutFade = false
local noScrollRect = { left = noScrollAreaSize, top = noScrollAreaSize, right = 255 - noScrollAreaSize, bottom = 158 - noScrollAreaSize }

-- [ ROM/RAM addresses ] -------------------------------------------------------

RAM = {
	fadeLevel = 0x7e0c5b,         -- screen fade level
	pauseFlag = 0x7e0266,         -- becomes 1 when the game is paused
	overworldFlag = 0x7e0980,     -- becomes 1 when the game is overworld map
	roomTransition = 0x7e1c6c,    -- becomes 1 while room transition
	roomTransitionAlt = 0x7e0021, -- changes faster than roomTransition (non-zero = room transition possibly)
	frames = 0x7e1300, minutes = 0x7e1302, -- ingame timer
	arlePosWord = 0x7e16c5,     -- Arle's position in OW (0byyyyyyyyyxxxxxxx)
	arleXPosR = 0x7e0025, arleYPosR = 0x7e0027,
	arleXPosW = 0x7e4827, arleYPosW = 0x7e4829,
	bgXPosW = 0x7e16e2, bgYPosW = 0x7e16e6,
	roomLeft = 0x7e1733, roomTop = 0x7e172f, roomRight = 0x7e1735, roomBottom = 0x7e1731,
	roomId = 0x7e14d7, roomAddr = 0x7e13fa,
	spriteAnimeCount1 = 0x7e172e, spriteAnimeCount2 = 0x7e172d,
	forestOfLightScrollParam = 0x7eb10a, forestOfLightAnimeParam = 0x7eb123,
	darkOfLightCloudH = 0x7eb110, darkOfLightCloudV = 0x7eb112, darkOfLightCloudBlur = 0x7eb102,
	rainScroll1 = 0x7eb10b, rainScroll2 = 0x7eb10f, rainAnime1 = 0x7eb121, rainAnime2 = 0x7eb123, -- byte
	disableOWMove = 0x7e1401,
	encounter = 0x7e1408
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

-- draw traditional arrow cursor (for video logging) ;)
function gui.drawarrowcursor(x, y, color, outlineColor)
	if color == nil then color = "white" end
	if outlineColor == nil then outlineColor = "black" end
	gui.line(x, y, x, y+16, outlineColor)
	gui.line(x+1, y+1, x+11, y+11, outlineColor)
	gui.line(x+1, y+15, x+3, y+13, outlineColor)
	gui.line(x+7, y+11, x+10, y+11, outlineColor)
	gui.line(x+4, y+12, x+7, y+19, outlineColor)
	gui.line(x+7, y+12, x+10, y+19, outlineColor)
	gui.line(x+8, y+20, x+9, y+20, outlineColor)
	gui.line(x+1, y+2, x+1, y+14, color)
	gui.line(x+2, y+3, x+2, y+13, color)
	gui.line(x+3, y+4, x+3, y+12, color)
	gui.line(x+4, y+5, x+4, y+11, color)
	gui.line(x+5, y+6, x+5, y+13, color)
	gui.line(x+6, y+7, x+6, y+15, color)
	gui.line(x+7, y+8, x+7, y+10, color)
	gui.line(x+8, y+9, x+8, y+10, color)
	gui.pixel(x+9, y+10, color)
	gui.line(x+7, y+14, x+7, y+17, color)
	gui.line(x+8, y+16, x+8, y+19, color)
	gui.line(x+9, y+18, x+9, y+19, color)
end
function gui.drawarrowcursorwithshadow(x, y, color, outlineColour)
	gui.drawarrowcursor(x+1, y+1, "#00000080", "#00000080")
	gui.drawarrowcursor(x, y, color, outlineColour)
end

-- [ core routines ] -----------------------------------------------------------

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
local mouse, mouseClipped = {}, {}
for k in pairs(allpads) do padTime[k] = 0 end
for k in pairs(allkeys) do keyTime[k] = 0 end

if imagePieceSize.x > 256 or imagePieceSize.y > 159 or (math.floor(imagePieceSize.y % 8) ~= 0) then
	error("Image piece size is invalid. The size must be smaller than 256x159. Also, the height must be a multiple of 8.")
end
local snapInfo = { x = 0, y = 0, width = imagePieceSize.x, height = imagePieceSize.y }
function getRoomInfo()
	local room = {
		left = memory.readwordsigned(RAM.roomLeft),
		top = memory.readwordsigned(RAM.roomTop),
		right = memory.readwordsigned(RAM.roomRight),
		bottom = memory.readwordsigned(RAM.roomBottom)
	}
	room.scrollWidth, room.scrollHeight = room.right - room.left, room.bottom - room.top
	room.width, room.height = room.scrollWidth + 256, room.scrollHeight + 159
	room.xPieces = math.ceil(room.width / snapInfo.width)
	room.yPieces = math.ceil(room.height / snapInfo.height)

	room.id = memory.readword(RAM.roomId)
	room.addr = bit.lshift(memory.readbyte(RAM.roomAddr+2), 16) + memory.readword(RAM.roomAddr)

	return room
end
local room = getRoomInfo()

local captStates = {
	enterPause = 0,
	quitPause = 1,
	doScreenShot = 2,
	didScreenShot = 3,
	endMapMaking = 4
}
local captState
local stateTimeCount
local scriptFrameCount = 0
local snapRoomInfo, gdMap, snapProgress
function mapCaptInit()
	snapRoomInfo = getRoomInfo()
	snapProgress = { x = snapRoomInfo.xPieces - 1, y = snapRoomInfo.yPieces - 1 }
	gdMap = gd.createTrueColor(snapRoomInfo.width, snapRoomInfo.height)
	if not gdMap then
		error("Memory allocation error (gd.createTrueColor failed)")
	end

	captState = captStates.enterPause
	stateTimeCount = 0

	capturingMap = true
end

function mapCaptFinish()
	local screenshotOK = false
	if gdMap then
		if string.match(imageFileName, "%a+.png") then
			screenshotOK = gdMap:pngEx(imageFileName, pngCompressLevel)
		else
			if string.match(imageFileName, "%a+.jpe?g") then
				screenshotOK = gdMap:jpeg(imageFileName, jpegQuality)
			elseif string.match(imageFileName, "%a+.gif") then
				screenshotOK = gdMap:gif(imageFileName)
			end
			if not screenshotOK then
				screenshotOK = gdMap:pngEx(imageFileName..".png", pngCompressLevel)
			end
		end
		gdMap = nil
	end

	capturingMap = false -- disable recursive call first
	savestate.load(savMapCaptStart, "quiet")

	if screenshotOK then
		emu.message("Saved the map image of the room.")
	else
		emu.message("Failed to take the screenshot.")
	end
end

function mapCaptStartup()
	if memory.readbyte(RAM.fadeLevel) ~= 15 or memory.readbyte(RAM.overworldFlag) ~= 1 then
		gui.popup("Let the game show the overworld screen, or the script won't run.")
		return false
	end

	if memory.readwordsigned(RAM.arleXPosW) % 8 ~= 0 or memory.readwordsigned(RAM.arleYPosW) % 8 ~= 0 then
		gui.popup("Arle's position is not a multiple of 8.")
		return false
	end

	if not noConfirm then
		local message = string.format([[The semi-auto map maker scans the game screen continuously, then makes a large map of the current room.

Before running the script, you may need to confirm some conditions.

  * The game must show the overworld screen. To make Arle stand about the center of the room makes the capture faster.
  * Make sure if "graphic clip windows" is OFF. It's needed to capture very left/right side of the screen. Usually, you can toggle it by pressing 8.
  * Make sure if "text in message" is OFF, or some of annoying texts will appear in the screenshot.
  * Make the frameskip rate to 0 in the room whose background is animated (ex. cloudy room).

Notes/Warnings:
%s
  * The script doesn't change the running speed at all, speedup the emulator manually if it's wanted.
  * Animated graphics will be somewhat paused, but it's not perfect at all.
  * It's semi-automated anyway, the capture sometimes fails.

Continue?]], (manualCapture and "\n  * The script is running under manual capture mode. You need to press 'start' button to capture a piece of the room map." or ""))
		if input.popup(message, "okcancel") ~= "ok" then
			return false
		end
		noConfirm = true
	end

	savestate.save(savMapCaptStart, "quiet")
	mapCaptInit()
	return true
end

local arleDragStart = { x = 0, y = 0, started = false }
local mouseDragLast = { x = 0, y = 0 }
local mouseOldDD = { x = -481, y = -801 }
function freeMoveOnBefore()
	if padDown.X then
		if pad.B then
			avoidEncounters = not avoidEncounters
		elseif memory.readbyte(RAM.overworldFlag) == 1 and memory.readbyte(RAM.disableOWMove) == 0 then
			mapCaptStartup()
			return
		end
	end
	if memory.readbyte(RAM.overworldFlag) ~= 1 then return end

	local mouseDD = { x = mouseClipped.x, y = mouseClipped.y }
	if mouseDD.y >= 159 then mouseDD.y = 159-1 end

	local bgX, bgY = memory.readwordsigned(RAM.bgXPosW), memory.readwordsigned(RAM.bgYPosW)
	local arleX, arleY = memory.readwordsigned(RAM.arleXPosW), memory.readwordsigned(RAM.arleYPosW)
	local arleRect = { left = arleX - bgX + 8, top = arleY - bgY - 19, right = arleX - bgX + 23, bottom = arleY - bgY + 8 }
	local arleNewPos = { x = arleX, y = arleY }
	local arleWasDragged = arleDragStart.started
	local bgScrollAmount = { x = 0, y = 0 }
	if memory.readbyte(RAM.disableOWMove) ~= 0 then
		-- you can read a conversation with click
		if keyDown.leftclick then pad.A = 1 end
		joypad.set(1, pad)
	end
	if arleDragStart.started then
		pad = {}
		joypad.set(1, pad)
	end

	if keyDown.leftclick then
		-- begin drag
		if ptInRect(arleRect, mouseDD) then
			arleDragStart.x, arleDragStart.y = arleX, arleY
			arleDragStart.started = true
		end
		mouseDragLast.x, mouseDragLast.y = mouseDD.x, mouseDD.y
	elseif key.leftclick then
		if memory.readbyte(RAM.roomTransitionAlt) ~= 0 then
			-- NYI: continue the drag after the room transition, if possible.
			arleDragStart.started = false
		else
			if arleDragStart.started then
				arleNewPos.x = arleNewPos.x + (mouseDD.x - mouseDragLast.x)
				arleNewPos.y = arleNewPos.y + (mouseDD.y - mouseDragLast.y)
				-- clip
				if arleNewPos.x < 0 then arleNewPos.x = 0 end
				if arleNewPos.y < 0 then arleNewPos.y = 0 end
				if arleNewPos.x > (room.left + room.width) then arleNewPos.x = room.left + room.width end
				if arleNewPos.y > (room.top + room.height) then arleNewPos.y = room.top + room.height end
				mouseDragLast.x, mouseDragLast.y = mouseDD.x, mouseDD.y
			end
		end
	elseif keyUp.leftclick then
		-- end drag
		arleDragStart.started = false
	end
	if not (arleWasDragged or arleDragStart.started) and key.rightclick then
		-- direct move (aka summon)
		arleNewPos.x, arleNewPos.y = bgX + mouseDD.x - 16, bgY + mouseDD.y
		-- clip
		if arleNewPos.x < 0 then arleNewPos.x = 0 end
		if arleNewPos.y < 0 then arleNewPos.y = 0 end
		if arleNewPos.x > (room.left + room.width) then arleNewPos.x = room.left + room.width end
		if arleNewPos.y > (room.top + room.height) then arleNewPos.y = room.top + room.height end
		-- update
		if arleNewPos.x ~= arleX then memory.writeword(RAM.arleXPosW, arleNewPos.x) end
		if arleNewPos.y ~= arleY then memory.writeword(RAM.arleYPosW, arleNewPos.y) end
	elseif keyUp.rightclick then
		-- align
		arleNewPos.x = math.floor((arleNewPos.x + 4) / 8) * 8
		arleNewPos.y = math.floor((arleNewPos.y + 4) / 8) * 8
		-- update
		if arleNewPos.x ~= arleX then memory.writeword(RAM.arleXPosW, arleNewPos.x) end
		if arleNewPos.y ~= arleY then memory.writeword(RAM.arleYPosW, arleNewPos.y) end
	end
	local arleDragFinalize = (arleWasDragged and not arleDragStart.started)

	if (arleDragStart.started or arleDragFinalize) then -- and not (mouseDD.x == mouseOldDD.x and mouseDD.y == mouseOldDD.y)
		if not ptInRect(noScrollRect, mouse) then
			-- calc basic scroll speed
			if mouse.x <= noScrollRect.left then
				bgScrollAmount.x = math.ceil((mouse.x - noScrollRect.left) * scrollSpeedScale)
			end
			if mouse.x >= noScrollRect.right then
				bgScrollAmount.x = math.ceil((mouse.x - noScrollRect.right) * scrollSpeedScale)
			end
			if mouse.y <= noScrollRect.top then
				bgScrollAmount.y = math.ceil((mouse.y - noScrollRect.top) * scrollSpeedScale)
			end
			if mouse.y >= noScrollRect.bottom then
				bgScrollAmount.y = math.ceil((mouse.y - noScrollRect.bottom) * scrollSpeedScale)
			end
			-- limit them
			if bgScrollAmount.x < -scrollSpeedMax then bgScrollAmount.x = -scrollSpeedMax end
			if bgScrollAmount.y < -scrollSpeedMax then bgScrollAmount.y = -scrollSpeedMax end
			if bgScrollAmount.x > scrollSpeedMax then bgScrollAmount.x = scrollSpeedMax end
			if bgScrollAmount.y > scrollSpeedMax then bgScrollAmount.y = scrollSpeedMax end

			-- BG scroll range limit
			if (bgX + bgScrollAmount.x) < room.left then
				bgScrollAmount.x = room.left - bgX
			end
			if (bgX + bgScrollAmount.x) > room.right then
				bgScrollAmount.x = room.right - bgX
			end
			if (bgY + bgScrollAmount.y) < room.top then
				bgScrollAmount.y = room.top - bgY
			end
			if (bgY + bgScrollAmount.y) > room.bottom then
				bgScrollAmount.y = room.bottom - bgY
			end

			memory.writeword(RAM.bgXPosW, bgX + bgScrollAmount.x)
			memory.writeword(RAM.bgYPosW, bgY + bgScrollAmount.y)
			arleNewPos.x = arleNewPos.x + bgScrollAmount.x
			arleNewPos.y = arleNewPos.y + bgScrollAmount.y
		end
		if arleDragFinalize then
			-- set her position to the multiple of 8
			arleNewPos.x = math.floor((arleNewPos.x + 4) / 8) * 8
			arleNewPos.y = math.floor((arleNewPos.y + 4) / 8) * 8
		end
		-- update
		if arleNewPos.x ~= arleX then memory.writeword(RAM.arleXPosW, arleNewPos.x) end
		if arleNewPos.y ~= arleY then memory.writeword(RAM.arleYPosW, arleNewPos.y) end
	end
	mouseOldDD = { x = mouseDD.x, y = mouseDD.y }

	if avoidEncounters then
		memory.writebyte(RAM.encounter, 62)
	end
end

function mapCaptOnBefore()
	if padDown.X then -- abort
		mapCaptFinish()
		return
	end

	local tookScreenShot = false
	if captState == captStates.enterPause then
		pad = {}

		-- adjust screen position
		local targetX, targetY = snapRoomInfo.left + (snapProgress.x * snapInfo.width), snapRoomInfo.top + (snapProgress.y * snapInfo.height)
		local targetStepX, targetStepY = math.floor((targetX + 0x70) / 8), math.floor((targetY + 0x58) / 8)
		local stepXMax, stepYMax = math.floor((snapRoomInfo.right + 256) / 8), math.floor((snapRoomInfo.bottom + 159) / 8)
		if targetStepX > stepXMax then targetStepX = stepXMax end
		if targetStepY > stepYMax then targetStepY = stepYMax end
		local bgX, bgY = memory.readwordsigned(RAM.bgXPosW), memory.readwordsigned(RAM.bgYPosW)
		local arleX, arleY = memory.readwordsigned(RAM.arleXPosW), memory.readwordsigned(RAM.arleYPosW)
		local stepX, stepY = math.floor(arleX/8), math.floor(arleY/8)
		local realStepX, realStepY = math.floor(memory.readword(RAM.arlePosWord) % 128), math.floor(memory.readword(RAM.arlePosWord) / 128)
		local moveSpeed = 8 -- do not change

		if stepX == targetStepX and stepY == targetStepY then
			if stateTimeCount < 4 then
				memory.writebyte(RAM.disableOWMove, 0)
			elseif memory.readbyte(RAM.overworldFlag) == 1 and memory.readword(RAM.frames) % 2 == 0 then
				if memory.readbyte(RAM.disableOWMove) ~= 0 then
					-- something has opened a dialog!
					-- skip the segment for the time being :(
					captState = captStates.doScreenShot
					tookScreenShot = true
					snapProgress.x = snapProgress.x - 1
					if not (snapProgress.x >= 0) then
						snapProgress.x = snapRoomInfo.xPieces - 1
						snapProgress.y = snapProgress.y - 1
					end
				else
					pad.start = 1 -- autofire the start button
				end
			end
		else
			pad = {}
			if stepX < targetStepX then
				bgX = bgX + moveSpeed
				arleX = arleX + moveSpeed
				stepX = stepX + 1
			elseif stepX > targetStepX then
				bgX = bgX - moveSpeed
				arleX = arleX - moveSpeed
				stepX = stepX - 1
			end
			if stepY < targetStepY then
				bgY = bgY + moveSpeed
				arleY = arleY + moveSpeed
				stepY = stepY + 1
			elseif stepY > targetStepY then
				bgY = bgY - moveSpeed
				arleY = arleY - moveSpeed
				stepY = stepY - 1
			end

			-- clipping
			if bgX < snapRoomInfo.left   then bgX = snapRoomInfo.left end
			if bgY < snapRoomInfo.top    then bgY = snapRoomInfo.top end
			if bgX > snapRoomInfo.right  then bgX = snapRoomInfo.right end
			if bgY > snapRoomInfo.bottom then bgY = snapRoomInfo.bottom end

			memory.writeword(RAM.bgXPosW, bgX)
			memory.writeword(RAM.bgYPosW, bgY)
			memory.writeword(RAM.arleXPosW, arleX)
			memory.writeword(RAM.arleYPosW, arleY)
			memory.writebyte(RAM.disableOWMove, 1)

			if stepX == targetStepX and stepY == targetStepY then
				stateTimeCount = 0
			end
		end
	elseif captState == captStates.quitPause then
		pad = {}
		if memory.readbyte(RAM.pauseFlag) == 1 and memory.readword(RAM.frames) % 2 == 0 then
			pad.start = 1 -- autofire the start button
		end
	elseif captState == captStates.doScreenShot then
		local startPressed = (pad.start ~= nil)
		pad = {}

		local eliminateMagic = 0xfade
		if eliminateMagic >= 0x8000 then eliminateMagic = eliminateMagic - 0x10000 end
		local noEliminate = false -- usually false
		if not noEliminate and memory.readwordsigned(RAM.arleXPosW) ~= eliminateMagic then
			-- eliminate Arle from the screenshot
			memory.writeword(RAM.arleXPosW, eliminateMagic)
			memory.writeword(RAM.arleYPosW, eliminateMagic)
			renderedWIthoutFade = false -- render required
		elseif renderedWIthoutFade then
			local doCapture = false
			if manualCapture then
				doCapture = startPressed
			else
				-- auto capture
				doCapture = stateTimeCount >= 90 -- Note: the following cloud stopper is somewhat imcomplete :(
					or (stateTimeCount >= 20 and memory.readword(RAM.rainScroll1) == 0)
					--or (stateTimeCount >= 20 and memory.readword(RAM.darkOfLightCloudH) == 0)
			end
			if doCapture then
				local gdSnap = gd.createFromGdStr(gui.gdscreenshot())
				local mapX, mapY = snapProgress.x * snapInfo.width, snapProgress.y * snapInfo.height
				local ofsX, ofsY = 0, 0
				local width, height = snapInfo.width, snapInfo.height
				if (snapProgress.x + 1) == snapRoomInfo.xPieces then ofsX, width  = 256 - (room.width  - mapX), room.width - mapX end
				if (snapProgress.y + 1) == snapRoomInfo.yPieces then ofsY, height = 159 - (room.height - mapY), room.height - mapY end
				--if (snapProgress.x + 1) == snapRoomInfo.xPieces then mapX, ofsX = snapRoomInfo.width - snapInfo.width, 256 - snapInfo.width end
				--if (snapProgress.y + 1) == snapRoomInfo.yPieces then mapY, ofsY = snapRoomInfo.height - snapInfo.height, 159 - snapInfo.height end
				gd.copy(gdMap, gdSnap, mapX, mapY, snapInfo.x + ofsX, snapInfo.y + ofsY, width, height)
				gdSnap = nil
				tookScreenShot = true

				snapProgress.x = snapProgress.x - 1
				if not (snapProgress.x >= 0) then
					snapProgress.x = snapRoomInfo.xPieces - 1
					snapProgress.y = snapProgress.y - 1
				end
			end
		else
			stateTimeCount = 0
		end
	elseif captState == captStates.didScreenShot then
		pad = {}
		mapCaptLoadingState = true
		savestate.load(savMapCaptStart, "quiet")
	elseif captState == captStates.endMapMaking then
		pad = {}
		mapCaptFinish()
	end
	joypad.set(1, pad)
	stateTimeCount = stateTimeCount + 1

	-- state transition
	local newState = captState
	if captState == captStates.enterPause then
		if memory.readbyte(RAM.pauseFlag) == 1 then
			newState = captStates.quitPause
		end
	elseif captState == captStates.quitPause then
		if memory.readbyte(RAM.overworldFlag) == 1 and memory.readbyte(RAM.fadeLevel) == 15 then
			newState = captStates.doScreenShot
		end
	elseif captState == captStates.doScreenShot then
		if tookScreenShot then
			if not (snapProgress.y >= 0) then
				newState = captStates.endMapMaking
			else
				newState = captStates.didScreenShot
			end
		end
	elseif captState == captStates.didScreenShot then
		newState = captStates.enterPause
	end
	if captState ~= newState then
		captState = newState
		stateTimeCount = 0
	end

	-- disable encounter
	memory.writebyte(RAM.encounter, 0)
	-- disable sprite animation
	memory.writebyte(RAM.spriteAnimeCount1, 0)
	--memory.writebyte(RAM.spriteAnimeCount2, 7)
	-- stop particles in Forest Of Light
	memory.writeword(RAM.forestOfLightScrollParam, 0)
	memory.writeword(RAM.forestOfLightAnimeParam, 0)
	-- stop clouds in Forest Of Dark, etc.
	memory.writeword(RAM.darkOfLightCloudH, math.floor(memory.readwordsigned(RAM.bgXPosW) % 256))
	memory.writeword(RAM.darkOfLightCloudV, math.floor(memory.readwordsigned(RAM.bgYPosW) % 256))
	memory.writeword(RAM.darkOfLightCloudBlur, 0)
	-- Forest Of Rain
	memory.writebyte(RAM.rainScroll1, 0)
	memory.writebyte(RAM.rainScroll2, 0)
	memory.writebyte(RAM.rainAnime1, 12)
	memory.writebyte(RAM.rainAnime2, 28)
end

function guiCommonInfoDisplay()
	local safeTiming = (not capturingMap or captState == captStates.enterPause)
	local fadeLevel = memory.readbyte(RAM.fadeLevel)
	if fadeLevel > 15 then fadeLevel = 0 end

	gui.opacity(guiOpacityMax * (fadeLevel / 30.0 + 0.5))
	if safeTiming then
		local totalFrames = (3600 * memory.readword(RAM.minutes)) + memory.readword(RAM.frames)
		local ingameTime = formatseconds(totalFrames/60.0)
		local encounterModeText = "ENCOUNTER " .. (avoidEncounters and "OFF" or "ON")
		gui.text(255 - (#ingameTime * 4), 1, ingameTime)
		if not capturingMap then
			gui.text(255 - (#encounterModeText * 4), 9, encounterModeText)
		end
	end
	gui.opacity(guiOpacityMax * fadeLevel / 15.0)
	if memory.readbyte(RAM.overworldFlag) ~= 1 then return end

	local mapX, mapY = 0, 0
	local ofsX, ofsY = 0, 0
	if capturingMap then
		mapX, mapY = snapProgress.x * snapInfo.width, snapProgress.y * snapInfo.height
		if (snapProgress.x + 1) == snapRoomInfo.xPieces then ofsX = 256 - (room.width  - mapX) end
		if (snapProgress.y + 1) == snapRoomInfo.yPieces then ofsY = 159 - (room.height - mapY) end
	end

	local bgX, bgY = memory.readwordsigned(RAM.bgXPosW), memory.readwordsigned(RAM.bgYPosW)
	local debugDisplayText = ""
	if safeTiming or (capturingMap and snapProgress.x == 0 and snapProgress.y == 0) then
		debugDisplayText = debugDisplayText .. string.format("SIZE (%03X-%03X,%03X-%03X)\n", room.left, room.right, room.top, room.bottom)
	end
	debugDisplayText = debugDisplayText .. string.format("BACK (%03X,%03X)\n", bit.band(bgX, 0xffff), bit.band(bgY, 0xffff))

	if safeTiming then
		local arleX, arleY = memory.readwordsigned(RAM.arleXPosW), memory.readwordsigned(RAM.arleYPosW)
		local realStepX, realStepY = math.floor(memory.readword(RAM.arlePosWord) % 128), math.floor(memory.readword(RAM.arlePosWord) / 128)
		debugDisplayText = debugDisplayText .. string.format("ARLE (%03X,%03X)", bit.band(arleX, 0xffff), bit.band(arleY, 0xffff)) --[[ .. string.format(" (%d,%d)", realStepX, realStepY) ]]-- .. "\n"
	end

	local colCaptureBox = "#00000080"
	if safeTiming then
		local opac = math.floor(scriptFrameCount % 64)
		if opac >= 32 then opac = 64 - opac end
		gui.opacity(guiOpacityMax * (opac/32.0))
		gui.box(snapInfo.x, snapInfo.y, snapInfo.x + snapInfo.width - 1, snapInfo.y + snapInfo.height - 1, colCaptureBox)
		gui.opacity(guiOpacityMax * fadeLevel / 15.0)
	elseif roomInfoInMapImage then
		gui.line(snapInfo.x, snapInfo.y + snapInfo.height - 1, snapInfo.x + snapInfo.width - 1, snapInfo.y + snapInfo.height - 1, colCaptureBox) -- bottom
		gui.line(snapInfo.x + snapInfo.width - 1, snapInfo.y, snapInfo.x + snapInfo.width - 1, snapInfo.y + snapInfo.height - 1 - 1, colCaptureBox) -- right
	end

	if safeTiming or roomInfoInMapImage then
		gui.text(1+ofsX, (capturingMap and snapProgress.x == 0 and snapProgress.y == 0) and 9 or (not safeTiming and (1+ofsY) or 28), debugDisplayText)
	end

	if safeTiming or (roomInfoInMapImage and capturingMap and snapProgress.x == 0 and snapProgress.y == 0) then
		gui.fillbox(0, 0, 65, 8, "#0000ffc0")
		gui.text(1, 1, string.format("ROOM %03X- %06X", room.id, room.addr), "white", "clear")
	end
end

function guiFreeMoveOnDraw()
	if memory.readbyte(RAM.overworldFlag) ~= 1 then return end
	local fadeLevel = memory.readbyte(RAM.fadeLevel)
	if fadeLevel > 15 then fadeLevel = 0 end

	if drawCursor then
		if key.leftclick then
			gui.drawarrowcursorwithshadow(mouse.x+1, mouse.y+1, "red")
		elseif key.rightclick then
			gui.drawarrowcursorwithshadow(mouse.x+1, mouse.y+1, "yellow")
		else
			gui.drawarrowcursorwithshadow(mouse.x, mouse.y)
		end
	end

	local bgX, bgY = memory.readwordsigned(RAM.bgXPosW), memory.readwordsigned(RAM.bgYPosW)
	local arleX, arleY = memory.readwordsigned(RAM.arleXPosW), memory.readwordsigned(RAM.arleYPosW)
	local arleRect = { left = arleX - bgX + 8, top = arleY - bgY - 19, right = arleX - bgX + 23, bottom = arleY - bgY + 8 }

	gui.box(arleRect.left, arleRect.top, arleRect.right, arleRect.bottom, "white")
end

-- [ main routines ] -----------------------------------------------------------

savestate.registerload( function()
	if capturingMap and not mapCaptLoadingState then
		mapCaptFinish()
	end
	mapCaptLoadingState = false
end)

emu.registerexit( function()
	if capturingMap then
		mapCaptFinish()
	end
	emu.registerbefore(nil)
	emu.registerafter(nil)
	gui.register(nil)
end)

emu.registerbefore( function()
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
	keyOld = key
	-- clipped cursor position
	mouseClipped = { x = mouse.x, y = mouse.y }
	if mouseClipped.x < 0 then mouseClipped.x = 0 end
	if mouseClipped.y < 0 then mouseClipped.y = 0 end
	if mouseClipped.x >= 256 then mouseClipped.x = 256-1 end
	if mouseClipped.y >= 224 then mouseClipped.y = 224-1 end

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

	room = getRoomInfo()
	if capturingMap then
		mapCaptOnBefore()
	else
		freeMoveOnBefore()
	end
end)

emu.registerafter( function()
	scriptFrameCount = scriptFrameCount + 1
end)

gui.register( function()
	renderedWIthoutFade = memory.readbyte(RAM.fadeLevel) == 15
	guiCommonInfoDisplay()
	if not capturingMap then
		guiFreeMoveOnDraw()
	end
end)

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
