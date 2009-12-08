-- Play SM2 segment
--   * reset is NOT supported.
--   * movie playback always starts from NOW, not reset or snapshot.
-- This script might help to merge an existing movie with slight timing changes.

require("smvlib")

local kmv_path = "input.sm2"
local kmv_framecount = 1 -- 1 = first frame
local skiplagframe = not true

print("Loading...")
print("(If movie is long this might take awhile, please be patient and do not kill script)")
local kmvfile = io.open(kmv_path, "r")
if not kmvfile then
	error('could not open "'..kmv_path..'"')
end
local kmv = sm2Import(kmvfile)
local controllers = {}
for pad = 1, 5 do
	if kmv.frame[1].joypad[pad] ~= nil then
		table.insert(controllers, pad)
	end
end

function exitFunc()
	if kmvfile then
		kmvfile:close()
	end
end

-- when this function return false,
-- script will send previous input and delay to process input.
function sendThisFrame()
	return true
end

local pad_prev = {}
for i, v in ipairs(controllers) do
	pad_prev[v] = joypad.get(v)
end
local frameAdvance = false
emu.registerbefore(function()
	if kmv_framecount > #kmv.frame then
		print("movie playback stopped.")
		emu.registerbefore(nil)
		emu.registerafter(nil)
		emu.registerexit(nil)
		gui.register(nil)
		exitFunc()
		return
	end

	frameAdvance = sendThisFrame()
	for i, v in ipairs(controllers) do
		local pad = pad_prev[v]
		if frameAdvance then
			for k in pairs(pad) do
				pad[k] = kmv.frame[kmv_framecount].joypad[v][k]
			end
		end
		joypad.set(v, pad)
		pad_prev[v] = copytable(pad)
	end
end)

emu.registerafter(function()
	local lagged = skiplagframe and emu.lagged()
	if frameAdvance and not lagged then
		if lagged then
			-- print(string.format("%06d", emu.framecount()))
		end
		kmv_framecount = kmv_framecount + 1
	end
end)

emu.registerexit(exitFunc)

gui.register(function()
	gui.text(0, 0, ""..(kmv_framecount-1).."/"..#kmv.frame)
end)
