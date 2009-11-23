-- Kirby's Dream Course - Cut everything except gameplay

local frameOffset = nil
local renderStartedAt = nil
local firstTrim = true

function avsWriteLine(str)
	-- if true then return end
	print(str)

	if not avs then
		-- avs = io.open("C:\\KirbysDreamCourse.avs", "w")
	end
	if avs then
		avs:write(tostring(str), "\n")
	end
end

function renderThisFrame()
	local duringCupInSound = memory.readbyte(0x7e6ac0)~=2 and (memory.readword(0x7e1ffc)==0x80f5 or memory.readword(0x7e1ffc)==0xcb83 or memory.readword(0x7e1ffc)==0xd300)
	local duringOnWarp = (memory.readbyte(0x7e6a48)==1) -- memory.readbyte(0x7e1edd)==0 or memory.readbyte(0x7e6a48)==1)
	local duringCameraMoveOnWarp = (memory.readbyte(0x7e1edd)==0 and memory.readbyte(0x7e659c)==255)
	local duringWaterSwitchAnimation = (memory.readword(0x7e0858)==0)
	local duringUFOBootUp = (memory.readword(0x7ed9c6)==10 and memory.readword(0x7ed9c8)==10 and memory.readword(0x7ed776)==600) -- (memory.readbyte(0x7e0302)==1 and memory.readbyte(0x7eda52)==1)

	return (
		(memory.readbyte(0x7e6ac0)==2 -- during a shot
		and memory.readbyte(0x7e6850)~=8 -- not during ability boot
		and not duringOnWarp
		and not duringWaterSwitchAnimation
		and not duringUFOBootUp
		or duringCupInSound
		)
		and memory.readbyte(0x7e6a8c)~=1 -- but not during the transform of the last enemy
	) -- or (not movie.active())
end

function writeTrimLine(framecount)
	if renderStartedAt then
		if firstTrim then
			avsWriteLine('AviSource("source.avi")+AviSource("source_part2.avi")+AviSource("source_part3.avi")')
			avsWriteLine('FlipVertical()') -- for CorePNG

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

gui.register(function() if not renderThisFrame() then gui.box(0, 0, 1000, 1000, "#0000ffc0") end end)
