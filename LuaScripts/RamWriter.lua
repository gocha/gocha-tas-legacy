----------------------------------------------------------
-- RamWriter.lua: log variables for advanced video encode.
----------------------------------------------------------

--if not emu then
--	error("This script runs under DeSmuME.")
--end

----------------------------------------------------------
-- Open log file first
----------------------------------------------------------
local file = io.open("framedata.txt", "w")
if file == nil then
	error("File could not be opened.")
end

----------------------------------------------------------
-- Do logging at the end of frame
----------------------------------------------------------
emu.registerafter(function()
	-- TODO: modify the following code to change the content of log output.
	file:write(string.format("%d ", emu.framecount()))
	file:write(string.format("%d ", emu.lagcount()))
	file:write(string.format("%d ", (emu.lagged() and 1 or 0)))
	file:write(string.format("%u ", memory.readdword(0x020ca95c))) -- x
	file:write(string.format("%u ", memory.readdword(0x020ca960))) -- y
	file:write(string.format("%d ", memory.readdwordsigned(0x020ca968))) -- xv
	file:write(string.format("%d ", memory.readdwordsigned(0x020ca96c))) -- yv
	file:write(string.format("%d ", memory.readdword(0x020f703c))) -- ingame time
	file:write("\n")
end)

----------------------------------------------------------
-- Script terminated, finalize log file
----------------------------------------------------------
emu.registerexit(function()
	file:close()
end)
