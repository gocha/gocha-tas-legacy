-- This script tests whether the savestate implementations are stable.
-- http://tasvideos.org/LawsOfTAS/OnSavestates.html

-- ===Story===
-- start recording movie_1.mov (movie mode becomes RECORDING)
-- press A button for 100 frames
-- save savestate #1
-- press B button for 100 frames
-- save savestate #2
-- press X button for 100 frames
-- load savestate #2 (shortens the movie length)
-- switch from read+write to read-only
-- load savestate #1 (movie mode becomes PLAYING)
-- checkpoint #1: emulator loads a valid movie snapshot
-- checkpoint #2: emulator switches movie mode from RECORDING to PLAYING [movie snapshot load] (also, movie should be saved to the disk)
-- checkpoint #3: user cannot input while playing a movie
-- frame advance for 101 frames
-- checkpoint #4: emulator switches movie mode from PLAYING to FINISHED [reaches the end]
-- checkpoint #5: user can input if movie has been finished
-- checkpoint #6: user can close movie if movie has been finished (check the menu)
-- frame advance if needed (to verify checkpoint #5 and checkpoint #6)
-- save savestate #3
-- close movie_1.mov (movie mode becomes INACTIVE)
-- save savestate #4
-- load savestate #1
-- checkpoint #7: emulator just loads movie snapshot without altering any movie things, when it had not been playing a movie
-- frame advance if needed (to verify checkpoint #7)
-- start recording movie_2.mov (movie mode becomes RECORDING)
-- press A button for 100 frames
-- press X button for 100 frames
-- switch from read+write to read-only
-- load savestate #1
-- checkpoint #8: emulator raises GUID unmatch error
-- checkpoint #9: emulator cancels loading a savestate, movie mode keeps RECORDING [GUID unmatch]
-- checkpoint #9: (optional) user can force to load it, it should just change the current frame counter (next button press must be X)
-- frame advance if needed (to verify checkpoint #8 and checkpoint #9)
-- close movie_2.mov (movie mode becomes INACTIVE)
-- start playing movie_1.mov (movie mode becomes PLAYING)
-- switch from read-only to read+write
-- load savestate #1 (movie mode becomes RECORDING)
-- press X button for 150 frames
-- switch from read+write to read-only
-- load savestate #2
-- checkpoint #10: emulator raises movie timeline inconsistent error
-- checkpoint #11: emulator cancels loading a savestate, movie mode keeps RECORDING [timeline inconsistent]
-- checkpoint #11: (optional) user can force to load it, it should just change the current frame counter (next button press must be X for 50 frames, then B for 50 frames)
-- frame advance if needed (to verify checkpoint #10 and checkpoint #11)
-- switch to read+write
-- load savestate #2 (movie mode becomes RECORDING)
-- load savestate #4 (movie mode becomes FINISHED)
-- checkpoint #12: emulator switches movie mode from RECORDING to FINISHED [load non-movie snapshot from RECORDING] (also, movie should be saved to the disk)
-- checkpoint #5': user can input if movie has been finished (just in case)
-- frame advance if needed (to verify checkpoint #12)
-- load savestate #2 (movie mode becomes RECORDING)
-- switch from read+write to read-only
-- load savestate #1 (movie mode becomes PLAYING)
-- load savestate #4 (movie mode becomes FINISHED)
-- checkpoint #13: emulator switches movie mode from PLAYING to FINISHED [load non-movie snapshot from PLAYING]
-- checkpoint #5': user can input if movie has been finished (just in case)
-- frame advance if needed (to verify checkpoint #13)
-- switch from read-only to read+write
-- load savestate #1 (movie mode becomes RECORDING)
-- load savestate #3 (movie mode becomes FINISHED)
-- checkpoint #14: emulator switches movie mode from RECORDING to FINISHED [load 'finished' movie snapshot while RECORDING]
-- frame advance if needed (to verify checkpoint #14)
-- switch from read+write to read-only
-- load savestate #2 (movie mode becomes PLAYING)
-- checkpoint #15: 'finished' movie snapshot contains the entire movie (i.e. emulator switches movie mode from FINISHED to PLAYING, movie length = 200 frames)
-- frame advance if needed (to verify checkpoint #15)
-- load savestate #1 (movie mode becomes PLAYING)
-- load savestate #3 (movie mode becomes FINISHED)
-- checkpoint #16: emulator switches movie mode from PLAYING to FINISHED [load 'finished' movie snapshot while PLAYING]
-- finish

local movieFilename1 = "movie_1.smv"
local movieFilename2 = "movie_2.smv"
local buttonTable = { "A", "B", "X" }

local step, frame = 0, 0

gui.register(function()
	local str = string.format("frame = %d", emu.framecount())
	str = str .. "\n" .. "movie.length() = " .. movie.length()
	str = str .. "\n" .. "movie.mode() = " .. movie.mode()
	str = str .. "\n" .. "movie.readonly() = " .. movie.readonly()
	str = str .. "\n" .. "movie.name() = " .. movie.name()
	str = str .. "\n" .. string.format("step,frame = %d,%d", step, frame)
	if gui.text then
		gui.text(40, 40, str)
	end
end)

emu.registerbefore(function()
	-- NYI
end)
