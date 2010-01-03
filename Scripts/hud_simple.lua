
gui.opacity(0.75)
gui.register(function()
	local frame = emu.framecount()
	local lagframe = emu.lagcount()
	local moviemode = ""

	moviemode = movie.mode()
	if not movie.active() then moviemode = "" end
	gui.text(1, 26, string.format("%d%s\n%d",
		frame,
		(moviemode ~= "" and string.format(" (%s)", moviemode) or ""),
		lagframe
	))
end)
