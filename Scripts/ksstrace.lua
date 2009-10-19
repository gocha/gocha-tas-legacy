-- Sample code for SNES Trace Logger (2009-10-20: latest svn build of snes9x required)
-- This script is written for Kirby Super Star (Hoshi no Kirby Super Deluxe) (J)
-- When the game enters RNG routine, the script begins trace logging in the console.

dofile("snestrace.lua")

local dotrace = true
local tracebuf = ""
local tracenum = 0
function runtracer(address, size)
	if dotrace then
		if tracebuf ~= "" then tracebuf = tracebuf .. "\r\n" end
		tracebuf = tracebuf .. gettraceline("sa1")
		tracenum = tracenum + 1
	end
end
emu.registerafter(function()
	if tracebuf ~= "" then
		print(tracebuf)
	end
	tracebuf = ""

	-- stop if it exceeds 1000 lines
	if dotrace and tracenum > 1000 then
		dotrace = false
		print("Tracer stopped.")
	end
end)
memory.registerexec(0x008a9c, 23, runtracer)
memory.registerexec(0x008ab3, 0x3a, runtracer)
