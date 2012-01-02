-- SNES Clocktower (J) Lua
-- works on snes9x-rr 1.43 v17
-- left-click won't work on snes9x-rr 1.51, press Y instead

local key = input.get()
local key_prev = nil
emu.registerbefore(function()
	key_prev = copytable(key)
	key = input.get()
	local onscreen = (key.xmouse >= 0 and key.xmouse <= 255 and key.ymouse >= 0 and key.ymouse <= 223)
	local clicked = (key.leftclick and not key_prev.leftclick)
	local pad = joypad.getdown(1)
	if onscreen then
		local x, y = math.max(10, math.min(key.xmouse, 223 + 10)), math.max(10, math.min(key.ymouse, 143 + 10))
		memory.writebyte(0x7e0f30, x - 10)
		memory.writebyte(0x7e0f32, y - 10)
		if clicked then
			pad.Y = true
			joypad.set(1, pad)
		end
	end
end)
