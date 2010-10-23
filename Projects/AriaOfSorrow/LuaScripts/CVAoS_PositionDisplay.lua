gui.opacity(0.68)
gui.register(function()
	if memory.readbyte(0x02000064) == 1 then
		local posX = memory.readwordsigned(0x0200a09a) * 0x10000 + memory.readdwordsigned(0x02000524)
		local posY = memory.readwordsigned(0x0200a09e) * 0x10000 + memory.readdwordsigned(0x02000528)
		gui.text(30, 18, string.format("%08X %08X", posX, posY))
	end
end)
