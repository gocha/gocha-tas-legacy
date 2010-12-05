gui.opacity(0.68)
gui.register(function()
	if memory.readbyte(0x02000048) == 1 or memory.readbyte(0x02000048) == 3 then
		local posX = memory.readwordsigned(0x0200a444) * 0x10000 + memory.readdwordsigned(0x02000460)
		local posY = memory.readwordsigned(0x0200a448) * 0x10000 + memory.readdwordsigned(0x02000464)
		gui.text(30, 18, string.format("%08X %08X", posX, posY))
	end
end)
