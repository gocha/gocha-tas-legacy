-- Kirby's Dream Course - Driving Ability

gravity  = 0x2000 -- game default: 0x5332
friction = 0x6665 -- game default: 0x6665

accelstep, accelmax, accelmaxspeed = 8, 0x70, 0x1200
decelstep, decelmax, decelminspeed = 6, 0x80, 0
backaccelstep, backaccelmax = 16, 0x100
rotatestep, rotatestepsuper = 2.0, 4.0
jumpspeed = 2666

minipadfname = nil -- "minipad.png" -- http://gocha-tas.googlecode.com/svn/trunk/Projects/KirbysDreamCourse/LuaScripts/minipad.png

-- [ initial check ] -----------------------------------------------------------

emu = emu or snes9x
if not emu then
	error("This script runs under SNES emulua host.")
end

-- [ generic utility functions ] -----------------------------------------------

if not bit then
	require("bit")
end

-- [ constants ] ---------------------------------------------------------------

RAM = {
	xv = 0x7ed9d4,
	yv = 0x7ed9d6,
	zv = 0x7ed9d8,
	flying = 0x7ed9ec,
	gravity = 0x7eda32,
	friction = 0x7eda36,
	player = 0x7e1803
}

-- [ global variables ] --------------------------------------------------------

pad, padold = {}, {}
accel, decel, backaccel = 0, 0, 0
backboostflipped = false

if minipadfname and minipadfname ~= "" then
	require "gd"
	minipad = gd.createFromPng(minipadfname)
	if not minipad then
		error("File not found: \""..minipadfname.."\"")
	end
end
padoverlaycolor = "#ff000080"

-- [ subroutines ] -------------------------------------------------------------

function clip16(v)
	return math.floor(math.max(0, math.min(65535, v)))
end

function clip16signed(v)
	return math.floor(math.max(-32768, math.min(32767, v)))
end

function readJoypad(player)
	pad = joypad.get(player)
	padtrig = {}
	for k, v in pairs(pad) do
		if not padold[k] and v then
			padtrig[k] = true
		end
	end
	padold = pad
end

function isPhysicsWorking()
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
		)
		and memory.readbyte(0x7e6a8c)~=1 -- but not during the transform of the last enemy
	)
end

emu.registerbefore(function()
	local player = ((memory.readbyte(RAM.player) == 2) and 2 or 1)
	readJoypad(player)

	memory.writeword(RAM.gravity, clip16(gravity))
	memory.writeword(RAM.friction, clip16(friction))

	if not isPhysicsWorking() then
		return
	end

	local dir = math.deg(math.atan2(memory.readwordsigned(RAM.yv), memory.readwordsigned(RAM.xv))) -- memory.readwordsigned(RAM.dir)
	local hv = math.sqrt(math.pow(memory.readwordsigned(RAM.xv), 2) + math.pow(memory.readwordsigned(RAM.yv), 2))
	local vv = memory.readwordsigned(RAM.zv)
	local flying = (memory.readword(RAM.flying)~=0)

	-- rotate
	if pad.left  then dir = dir + rotatestep end
	if pad.right then dir = dir - rotatestep end
	if pad.L     then dir = dir + rotatestepsuper end
	if pad.R     then dir = dir - rotatestepsuper end

	-- jump
	if padtrig.up then
		vv = jumpspeed
		flying = true
	end
	-- drop
	if pad.down then
		vv = vv - 256
	end

	if not pad.Y then accel, backaccel, backboostflipped = 0, 0, false end
	if not pad.X then decel, backboostflipped = 0, false end
	-- horizontal speed manipulation
	if pad.X and pad.Y and not backboostflipped then
		-- backboost
		backaccel = math.min(backaccel + backaccelstep, backaccelmax)
		hv = hv - backaccel
		if hv < 0 then
			hv = -hv
			dir = dir + 180
			backboostflipped = true
		end
	elseif pad.Y then
		-- speedup
		accel = math.min(accel + accelstep, accelmax)
		local newhv = hv + accel
		if newhv <= accelmaxspeed then
			hv = newhv
		end
	elseif pad.X then
		-- speeddown
		decel = math.min(decel + decelstep, decelmax)
		local newhv = math.max(hv - decel, 0)
		if newhv >= decelminspeed then
			hv = newhv
		end
	end

	memory.writeword(RAM.xv, clip16signed(hv * math.cos(math.rad(dir))))
	memory.writeword(RAM.yv, clip16signed(hv * math.sin(math.rad(dir))))
	memory.writeword(RAM.zv, clip16signed(vv))
	memory.writeword(RAM.flying, (flying and 1 or 0))
end)

gui.register(function()
	if minipad then
		local mode = memory.readbyte(0x7e6ac0)
		if mode == 2 then -- TODO: include more scenes
			gui.gdoverlay(2, 13, minipad:gdStr())
			local fillbutton = function(x, y, color)
				if color == nil then color = padoverlaycolor end
				gui.line(x + 1, y, x + 2, y, color)
 				gui.line(x, y + 1, x + 3, y + 1, color)
 				gui.line(x, y + 2, x + 3, y + 2, color)
				gui.line(x + 1, y + 3, x + 2, y + 3, color)
			end
			local fillbutton2 = function(x, y, color)
				if color == nil then color = padoverlaycolor end
				gui.line(x + 2, y, x + 3, y, color)
				gui.line(x + 1, y + 1, x + 3, y + 1, color)
				gui.line(x, y + 2, x + 2, y + 2, color)
				gui.line(x, y + 3, x + 1, y + 3, color)
			end
			if pad.right then fillbutton(15, 26) end
			if pad.down then fillbutton(12, 29) end
			if pad.up then fillbutton(12, 23) end
			if pad.left then fillbutton(9, 26) end
			if pad.A then fillbutton(44, 26) end
			if pad.B then fillbutton(40, 30) end
			if pad.X then fillbutton(40, 22) end
			if pad.Y then fillbutton(36, 26) end
			if pad.L then
				local color = padoverlaycolor
				gui.line(12, 14, 18, 14, color)
				gui.line(8, 15, 19, 15, color)
				gui.line(7, 16, 11, 16, color)
				gui.line(6, 17, 8, 17, color)
				gui.pixel(6, 18, color)
			end
			if pad.R then
				local color = padoverlaycolor
				gui.line(37, 14, 43, 14, color)
				gui.line(36, 15, 46, 15, color)
				gui.line(43, 16, 48, 16, color)
				gui.line(47, 17, 49, 17, color)
				gui.pixel(49, 18, color)
			end
			if pad.select then fillbutton2(22, 28) end
			if pad.start  then fillbutton2(27, 28) end
		end
	end
end)
