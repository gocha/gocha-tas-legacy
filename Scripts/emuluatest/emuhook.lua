count = 0

if emu.registerbefore then
	emu.registerbefore(function()
		print("emu.registerbefore", count)
		count = count + 1
	end)
else
	print("emu.registerbefore", "nil")
end

if emu.registerafter then
	emu.registerafter(function()
		print("emu.registerafter", count)
		count = count + 1
	end)
else
	print("emu.registerafter", "nil")
end

if emu.registerstart then
	emu.registerstart(function()
		print("emu.registerstart", count)
		count = count + 1
	end)
else
	print("emu.registerstart", "nil")
end

if emu.registerexit then
	emu.registerexit(function()
		print("emu.registerexit", count)
		count = count + 1
	end)
else
	print("emu.registerexit", "nil")
end
