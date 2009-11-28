-- Play DSM segment (desmume 0.9.5 or later)
--   * mic and reset are NOT supported.
--   * movie playback always starts from NOW, not reset or snapshot.
-- This script might help to merge an existing movie with slight timing changes.

require("dsmlib")

local dsm_path = "input.dsm"
local dsm_framecount = 1 -- 1 = first frame

local dsmfile = io.open(dsm_path, "r")
if not dsmfile then
	error('could not open "'..dsm_path..'"')
end
local dsm = dsmImport(dsmfile)

function exitFunc()
	if dsmfile then
		dsmfile:close()
	end
end

-- when this function return false,
-- script will send previous input and delay to process input.
function sendThisFrame()
	return true
end

local pad_prev = joypad.get()
local pen_prev = stylus.get()
emu.registerbefore(function()
	if dsm_framecount > #dsm.frame then
		print("movie playback stopped.")
		emu.registerbefore(nil)
		emu.registerafter(nil)
		emu.registerexit(nil)
		gui.register(nil)
		exitFunc()
		return
	end

	local pad = pad_prev
	local pen = pen_prev
	if sendThisFrame() then
		for k in pairs(pad) do
			pad[k] = dsm.frame[dsm_framecount][k]
		end
		pen.x = dsm.frame[dsm_framecount].touchX
		pen.y = dsm.frame[dsm_framecount].touchY
		pen.touch = dsm.frame[dsm_framecount].touched
		dsm_framecount = dsm_framecount + 1
	end
	joypad.set(pad)
	stylus.set(pen)
	pad_prev = copytable(pad)
	pen_prev = copytable(pen)
end)

emu.registerexit(exitFunc)

gui.register(function()
	gui.text(0, 0, ""..(dsm_framecount-1).."/"..#dsm.frame)
end)
