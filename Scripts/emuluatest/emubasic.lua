if emu.message then
	emu.message("Hello")
else
	print("emu.message", "nil")
end

if emu.framecount then
	print(emu.framecount())
else
	print("emu.framecount", "nil")
end

if emu.lagged then
	print(emu.lagged())
else
	print("emu.lagged", "nil")
end

if emu.lagcount then
	print(emu.lagcount())
else
	print("emu.lagcount", "nil")
end

if emu.emulating then
	print(emu.emulating())
else
	print("emu.emulating", "nil")
end

if emu.atframeboundary then
	print(emu.atframeboundary())
else
	print("emu.atframeboundary", "nil")
end
