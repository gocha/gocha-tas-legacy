emu.registerbefore(function()
	local t = joypad.get()
	for k in pairs(t) do
		-- nil: must process user input
		-- false: must disable user input
		--        but it should not effect while playing a movie
		t[k] = nil
	end
	joypad.set(t)
end)
