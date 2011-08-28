----------------------------------------------------------
-- RamWriter.lua: log variables for advanced video encode.
----------------------------------------------------------

--if not emu then
--	error("This script runs under DeSmuME.")
--end

local useAviFrameCount = avi and avi.framecount

----------------------------------------------------------
-- Open log file first
----------------------------------------------------------
local file = io.open("framedata.txt", "w") -- TODO: modify filename if needed
if file == nil then
	error("File could not be opened.")
end

local prev_avi_framecount = 0
local prev_framedata = ""
if useAviFrameCount then
	prev_avi_framecount = avi.framecount()
end
----------------------------------------------------------
-- Do logging at the end of frame
----------------------------------------------------------
emu.registerafter(function()
	local aviFrameFrom = emu.framecount()
	local aviFrameTo = emu.framecount()
	if useAviFrameCount then
		aviFrameFrom = prev_avi_framecount + 1
		aviFrameTo = avi.framecount()
		prev_avi_framecount = aviFrameTo
		assert(aviFrameFrom <= aviFrameTo)
	end

	-- process duplicated avi frames
	if aviFrameFrom < aviFrameTo then
		for aviFrame = aviFrameFrom, aviFrameTo - 1 do
			local framedata = ""
			-- framedata = framedata .. string.format("%d ", aviFrame)
			framedata = framedata .. prev_framedata
			file:write(framedata)
		end
	end

	-- main frame
	-- file:write(string.format("%d ", aviFrameTo))
	local framedata = ""

	-- TODO: modify the following code to change the content of log output.
	framedata = framedata .. string.format("%d ", emu.framecount())
	framedata = framedata .. string.format("%d ", emu.lagcount())
	framedata = framedata .. string.format("%d ", (emu.lagged() and 1 or 0))
	framedata = framedata .. string.format("%u ", memory.readdword(0x020ca95c)) -- x
	framedata = framedata .. string.format("%u ", memory.readdword(0x020ca960)) -- y
	framedata = framedata .. string.format("%d ", memory.readdwordsigned(0x020ca968)) -- xv
	framedata = framedata .. string.format("%d ", memory.readdwordsigned(0x020ca96c)) -- yv
	framedata = framedata .. string.format("%d ", memory.readdword(0x020f703c)) -- ingame time
	-- local pad = joypad.get(1)
	-- framedata = framedata .. string.format("%d ", (pad.A and 1 or 0))
	framedata = framedata .. "\n"

	file:write(framedata)
	prev_framedata = framedata
end)

----------------------------------------------------------
-- Script terminated, finalize log file
----------------------------------------------------------
emu.registerexit(function()
	file:close()
end)

----------------------------------------------------------
while emu.frameadvance do emu.frameadvance() end
