function get()
	if emu.message then
		emu.message("Hello")
	else
		print("emu.message", "nil")
	end

	if emu.framecount then
		print("emu.framecount", emu.framecount())
	else
		print("emu.framecount", "nil")
	end

	if emu.lagged then
		print("emu.lagged", emu.lagged())
	else
		print("emu.lagged", "nil")
	end

	if emu.lagcount then
		print("emu.lagcount", emu.lagcount())
	else
		print("emu.lagcount", "nil")
	end

	if emu.emulating then
		print("emu.emulating", emu.emulating())
	else
		print("emu.emulating", "nil")
	end

	if emu.atframeboundary then
		print("emu.atframeboundary", emu.atframeboundary())
	else
		print("emu.atframeboundary", "nil")
	end
end

get()

firstbefore = true
if emu.registerbefore then
	emu.registerbefore(function()
	if firstbefore then
		firstbefore = false
		print("------------------------------")
		print("[emu.registerbefore]")
		get()
	end
	end)
end

if emu.registerafter then
	firstafter = true
	emu.registerafter(function()
	if firstafter then
		firstafter = false
		print("------------------------------")
		print("[emu.registerafter]")
		get()
	end
	end)
end
