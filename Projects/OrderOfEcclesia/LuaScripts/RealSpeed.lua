local x, y = 0, 0
local xold, yold = 0, 0
local xv, yv

emu.registerafter(function()
	x = memory.readdword(0x2109850)
	y = memory.readdword(0x2109854)
	xv, yv = x - xold, y - yold
	xold, yold = x, y
end)

gui.register(function()
	agg.text(100, 100, string.format("%d %d", xv, yv))
end)
