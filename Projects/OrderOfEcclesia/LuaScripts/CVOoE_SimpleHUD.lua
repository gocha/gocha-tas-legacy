-- Castlevania: Order of Ecclesia
-- Simple RAM Display (good for livestreaming!)

local opacityMaster = 0.68
gui.register(function()
	local frame = emu.framecount()
	local lagframe = emu.lagcount()
	local moviemode = ""

	local igframe = memory.readdword(0x02100374)
	local ch_x = memory.readdwordsigned(0x02109850)
	local ch_y = memory.readdwordsigned(0x02109854)
	local ch_vx = memory.readdwordsigned(0x0210985c)
	local ch_vy = memory.readdwordsigned(0x02109860)
	local ch_inv = memory.readbyte(0x021098e5)
	local ch_mptimer = memory.readword(0x020ffec0)
	local hp = memory.readword(0x021002b4)
	local mp = memory.readword(0x021002b8)
	local mode = memory.readbyte(0x020d88d0)
	local fade = 1.0 -- math.min(1.0, 1.0 - math.abs(memory.readbytesigned(0x020f61fc)/16.0)) -- FIXME

	moviemode = movie.mode()
	if not movie.active() then moviemode = "no movie" end

	local framestr = ""
	if movie.active() and not movie.recording() then
		framestr = string.format("%d/%d", frame, movie.length())
	else
		framestr = string.format("%d", frame)
	end
	framestr = framestr .. (moviemode ~= "" and string.format(" (%s)", moviemode) or "")

	gui.opacity(opacityMaster)
	gui.text(1, 26, string.format("%s\n%d", framestr, lagframe))

	if mode == 0 then
		gui.opacity(opacityMaster * (fade/2 + 0.5))

		gui.text(1, 60, string.format("(%6d,%6d) %d %d\nHP%03d/MP%03d",
			ch_vx, ch_vy, ch_inv, ch_mptimer, hp, mp))

		-- enemy info
		local basead = 0x0210d308
		local dispy = 26
		for i = 0, 15 do
			local base = basead + i * 0x160
			if memory.readword(base) > 0 then -- hp
				gui.text(171, dispy, string.format("%X %03d %08X", i, memory.readword(base), memory.readdword(base-0xf8)))
				dispy = dispy + 10
			end
		end
	end
end)
