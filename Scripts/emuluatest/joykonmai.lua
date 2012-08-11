notPressed = joypad.get()
for k in pairs(notPressed) do
	notPressed[k] = false
end

framecount = 0
emu.registerbefore(function()
	local pad = copytable(notPressed)
	local konmai = { "start", "up", "", "up", "down", "", "down", "left", "right", "left", "right", "B", "A", "start" }
	if framecount <= (#konmai - 1) then
		local button = konmai[framecount + 1]
		if button ~= "" then
			pad[button] = true
		end
	end
	if framecount <= (#konmai - 1) then
		joypad.set(pad)
	end
end)

emu.registerafter(function()
	local lagged = false
	if emu.lagged then
		lagged = emu.lagged()
	end
	if not lagged then
		framecount = framecount + 1
	end
end)
