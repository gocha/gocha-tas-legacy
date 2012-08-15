--[[

 Gradius 3 + Mouse Control for Snes9x 1.43-rr
 This script looks working good on both (U) and (J) ROM.

 SHOT/MISSILE   LEFT CLICK
 POWERUP        RIGHT CLICK

 CAUTION!
 Do NOT change pad settings via OPTION. I don't care them at all.

 gocha -- http://tasvideos.org/forum/r/gocha

]]--

-- SCRIPT OPTION
local shotBehavior = 0 -- 0=auto, 1=leftClick(hold), 2=leftClick(trigger), 3=disable
local allowMouseAlways = true
local renderCursorInGame = false -- for video logging

gui.opacity(0.6)

--

emu = emu or snes9x
if not emu then
	error("This script runs under snes9x")
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
function gui.drawarrowcursorwithshadow(x, y)
	gui.drawarrowcursor(x+1, y+1, "#00000080", "#00000080")
	gui.drawarrowcursor(x, y)
end

local key, keyprev = {}, {}
local mouse, mouseprev = {}, {}
local gra3State = memory.readbyte(0x7e0070)
local gra3RewriteBehavior = false
local gra3Paused = false
emu.registerbefore(function()
	key = input.get()
	mouse = { x = math.max(0, math.min(255, key.xmouse)), y = math.max(0, math.min(223, key.ymouse)) }
	key.xmouse, key.ymouse = nil, nil

	gra3RewriteBehavior = false

	local padId = (memory.readbyte(0x7e007a) / 2) + 1
	if padId < 1 or padId > 2 then return end
	local pad = joypad.get(padId)

	gra3Paused = (memory.readbyte(0x7e0066) ~= 0)
	gra3State = memory.readbyte(0x7e0070)
	if gra3State ~= 6 then
		if allowMouseAlways then
			if key.leftclick then pad.A, pad.start = 1, 1 end
			if key.rightclick then pad.select = 1 end
			joypad.set(padId, pad)
		end
		return
	end

	gra3RewriteBehavior = true

	local x, y = mouse.x, mouse.y
	if not gra3Paused then
		pad.B = nil
		if shotBehavior == 3 then
			-- disable shooting
		elseif shotBehavior == 1 then
			if key.leftclick then pad.B = 1 end
		elseif shotBehavior == 2 then
			if key.leftclick and not keyprev.leftclick then pad.B = 1 end
		else
			pad.B = 1
			if key.leftclick then pad.B = nil end
		end
		if key.rightclick and not keyprev.rightclick then
			pad.A = 1
		else
			pad.A = nil
		end
		pad.left = 1 -- hold something to move options
		joypad.set(padId, pad)
	end

	if y >= 224 then y = 255 - 16 end
	memory.writebyte(0x7e020a, x)
	memory.writebyte(0x7e020e, y + 16)
end)

emu.registerafter(function()
	keyprev = key
	mouseprev = mouse
end)

gui.register(function()
	if renderCursorInGame then
		gui.drawarrowcursorwithshadow(mouse.x, mouse.y)
	end
end)
