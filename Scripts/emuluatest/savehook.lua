count = 0
emu.registerafter(function()
	count = count + 1
	-- print(count)
end)

savestate.registersave(function()
	print("save", count)
	return count
end)

savestate.registerload(function(_,a)
	count = a
	print("load", count)
end)
