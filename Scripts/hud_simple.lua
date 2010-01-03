
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

--[[
movie.active ()
Returns true if any movie file is open, or false otherwise.
movie.recording ()
Returns true if a movie file is currently recording, or false otherwise.
movie.playing ()
Returns true if a movie file is currently playing, or false otherwise.
movie.mode ()
Returns one of the following:

    * "playback": a movie file is currently playing
    * "record": a movie file is currently recording
    * "finished": a movie file is done playing but still open
    * nil: there is no movie file open 
   ]]
