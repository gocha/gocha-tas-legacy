-- Castlevania: Order of Ecclesia - Hitbox display

local colorHitboxOfShanoa = { 0, 255, 0, 192 }

if not emu then
	error("This script works under an emulua host (desmume)")
end

if not bit then
	require("bit")
end

-- [ main routines ] -----------------------------------------------------------

local RAM = {
	cameraX = 0x021000C8,
	cameraY = 0x021000CC,
	shanoaHitboxLeft = 0x02128c2e,
	shanoaHitboxTop = 0x02128c30,
	shanoaHitboxRight = 0x02128c32,
	shanoaHitboxBottom = 0x02128c34
}

function showHitboxOfShanoa()
	local shanoaRect = {
		left = memory.readwordsigned(RAM.shanoaHitboxLeft),
		top = memory.readwordsigned(RAM.shanoaHitboxTop),
		right = memory.readwordsigned(RAM.shanoaHitboxRight),
		bottom = memory.readwordsigned(RAM.shanoaHitboxBottom)
	}
	local camera = {
		x = bit.arshift(memory.readdwordsigned(RAM.cameraX), 12),
		y = bit.arshift(memory.readdwordsigned(RAM.cameraY), 12)
	}

	agg.noFill()
	agg.lineColor(unpack(colorHitboxOfShanoa))
	agg.lineWidth(1.0)
	agg.rectangle(shanoaRect.left - camera.x, shanoaRect.top - camera.y + 192, shanoaRect.right - camera.x, shanoaRect.bottom - camera.y + 192)
end

function showHitboxOfEnemy()
	-- TODO
end

gui.register(function()
	if memory.readword(0x020d88d0)==0 then -- FIXME: if duringGame then
		showHitboxOfShanoa()
		showHitboxOfEnemy()
	end
end)
