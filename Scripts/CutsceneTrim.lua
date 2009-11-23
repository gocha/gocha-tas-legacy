-- Smart Video Trimming by EmuLua + AviSynth

local frameOffset = nil
local renderStartedAt = nil
local firstTrim = true

function avsWriteLine(str)
	print(str)

	if not avs then
		-- avs = io.open("C:\\trim.avs", "w")
	end
	if avs then
		avs:write(tostring(str), "\n")
	end
end

function renderThisFrame()
	return not emu.lagged() -- skip all lag frames
end

function writeTrimLine(framecount)
	if renderStartedAt then
		if firstTrim then
			avsWriteLine('#AviSource("source.avi")')
			avsWriteLine(string.format("v=Trim(%d,%d)", renderStartedAt, framecount - 1))
			firstTrim = false
		else
			avsWriteLine(string.format("v=v+Trim(%d,%d)", renderStartedAt, framecount - 1))
		end
		renderStartedAt = nil
	end
end
emu.registerafter(function()
	if frameOffset == nil then
		frameOffset = emu.framecount()
	end

	local framecount = emu.framecount() - frameOffset
	if renderThisFrame() then
		if not renderStartedAt then
			renderStartedAt = framecount
		end
	else
		writeTrimLine(framecount)
	end
end)

emu.registerexit(function()
	writeTrimLine(emu.framecount() - frameOffset)
	avsWriteLine("v")
	if avs then
		avs:close()
	end
end)

-- gui.register(function() if not renderThisFrame() then gui.box(0, 0, 1000, 1000, "blue") end end)
