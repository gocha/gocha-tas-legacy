----------------------------------------------------------
-- RamWriterDofile.lua: log variables for advanced video encode.
----------------------------------------------------------

--if not emu then
--	error("This script runs under DeSmuME.")
--end

----------------------------------------------------------
-- Open log file first
----------------------------------------------------------
local file = io.open("framedata.lua.inl", "w") -- TODO: modify filename if needed
if file == nil then
	error("File could not be opened.")
end
file:write("frame={\n")

----------------------------------------------------------
-- Do logging at the end of frame
----------------------------------------------------------
emu.registerafter(function()
	-- TODO: modify the following code to change the content of log output.
	file:write("\t{")
	file:write(string.format("count=%d,", emu.framecount()))
	file:write(string.format("lagcount=%d,", emu.lagcount()))
	file:write(string.format("lagged=%s,", (emu.lagged() and "true" or "false")))
	file:write(string.format("x=%u,", memory.readdword(0x020ca95c)))
	file:write(string.format("y=%u,", memory.readdword(0x020ca960)))
	file:write(string.format("xv=%d,", memory.readdwordsigned(0x020ca968)))
	file:write(string.format("yv=%d,", memory.readdwordsigned(0x020ca96c)))
	file:write(string.format("time=%d,", memory.readdword(0x020f703c)))
	file:write("},\n")
end)

----------------------------------------------------------
-- Script terminated, finalize log file
----------------------------------------------------------
emu.registerexit(function()
	file:write("}\n")
	file:close()
end)
