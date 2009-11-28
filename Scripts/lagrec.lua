
local file = io.open("D:\\gocha\\work\\laglog.txt", "w")
if not file then
	error("file open error.")
end

emu.registerafter(function()
	if emu.lagged() then
		file:write(string.format("%06d\n", emu.framecount()))
		--file:write(string.format("%06d %s\n", emu.framecount(), (emu.lagged() and "*" or " ")))
	end
end)

emu.registerexit(function()
	if file then
		file:close()
	end
end)
