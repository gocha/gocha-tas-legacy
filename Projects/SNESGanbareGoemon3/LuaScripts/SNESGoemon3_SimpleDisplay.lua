-- Ganbare Goemon 3 (J) Simple Memory Display for TAS work

local showReturnPos = true
local showPlayerStatus = true
local showSpriteStatus = true

local opacityScale = 0.61803
local textcolor = "#ffffff"
local outlinecolor = "#303030"

-- [ initial check ] -----------------------------------------------------------

emu = emu or snes9x
if not emu then
	error("This script runs under SNES emulua host.")
end

-- [ generic utility functions ] -----------------------------------------------

if not bit then
	require("bit")
end

-- binary coded decimal encoder/decoder
function bcdof(n) return tonumber(tostring(n), 16) end
function bcd(n)   return tonumber(string.format("%x", n), 10) end

-- [ EmuLua utility functions ] ------------------------------------------------

function memory.readwordbyte(address)
	return bit.bor(bit.lshift(memory.readbyte(address + 2), 16), memory.readword(address))
end

function memory.readwordbytesigned(address)
	return bit.bor(bit.lshift(memory.readbytesigned(address + 2), 16), memory.readword(address))
end

gui.fontwidth = 4
gui.fontheight = 8

-- [ main ] --------------------------------------------------------------------

local RAM = {
	gameState = 0x7e0090,
	fadeLevel = 0x7e1fa0
}

local xposprev = { 0, 0 }
local yposprev = { 0, 0 }
local hudString = { "", "" }

-- Set up saves
savestate.registersave(function()
	-- print("save", xposprev[1], yposprev[1], xposprev[2], yposprev[2])
	return xposprev[1], yposprev[1], xposprev[2], yposprev[2]
end)
savestate.registerload(function(_,x1,y1,x2,y2)
	xposprev = { 0, 0 }
	yposprev = { 0, 0 }

	if x1 ~= nil then xposprev[1] = x1 end
	if y1 ~= nil then yposprev[1] = y1 end
	if x2 ~= nil then xposprev[2] = x2 end
	if y2 ~= nil then yposprev[2] = y2 end
	-- print("load", xposprev[1], yposprev[1], xposprev[2], yposprev[2])
end)

emu.registerafter(function()
	for player = 1, 2 do
		local base = 0x7e0400 + ((player-1)*0xc0)
		local lineofs = (player-1) * (1*gui.fontheight)
		local xcam = bit.lshift(memory.readword(0x7e1662), 8)
		local ycam = bit.lshift(memory.readword(0x7e1672), 8)
		local x = xcam + memory.readword(base+0x08)
		local y = ycam + memory.readword(base+0x0c)
		local xret = xcam + bit.lshift(memory.readword(base+0x80), 8)
		local yret = ycam + bit.lshift(memory.readword(base+0x82), 8)
		local xposdiff = x - xposprev[player]
		local yposdiff = y - yposprev[player]
		local walkerjump = memory.readbyte(0x7e042c)

		local dump = string.format("%dP: P(%06X,%06X) %4d,%4d", player, x, y, xposdiff, yposdiff)
		if showReturnPos and xret >= xcam and xret < (xcam + 0x10000) and yret >= ycam and yret < (ycam + 0x10000) then
			dump = dump .. string.format(" R(%06X,%06X)", xret, yret)
		end
		dump = dump .. string.format(" %d", walkerjump)
		hudString[player] = dump

		xposprev[player] = x
		yposprev[player] = y
	end
end)

gui.register(function()
	local fadeLevel = memory.readbyte(RAM.fadeLevel)
	if fadeLevel > 15 then fadeLevel = 0 end
	fadeLevel = fadeLevel / 15.0

	local gameState = memory.readbyte(RAM.gameState)
	if gameState == 2 or gameState == 4 then
		return
	end

	gui.opacity(opacityScale)
	if showPlayerStatus then
		for player = 1, 2 do
			local lineofs = (player-1) * (1*gui.fontheight)
			gui.text(1, 163+lineofs, hudString[player])
		end
	end

	if showSpriteStatus then
		for spriteId = 0, 63 do
			local spriteBase = 0x7e0300 + (spriteId * 0x50)
			if memory.readword(spriteBase) ~= 0 then
				local spriteAttr = memory.readbyte(spriteBase + 0x04)
				local spriteX = memory.readdword(spriteBase + 0x08)
				local spriteY = memory.readdword(spriteBase + 0x0c)
				local spriteZ = memory.readdword(spriteBase + 0x10)
				local spriteFlag1 = memory.readbyte(spriteBase + 0x14) -- shadow size etc?
				local spriteShadowOffset = memory.readbytesigned(spriteBase + 0x15)
				local spriteTypeId = memory.readword(spriteBase + 0x18)
				local spriteNextAddr = memory.readword(spriteBase + 0x16)
				local spriteActionId = memory.readword(spriteBase + 0x1a)
				local spriteTimer =  memory.readword(spriteBase + 0x20)
				local spriteXVel = memory.readwordsigned(spriteBase + 0x26)
				local spriteYVel = memory.readwordsigned(spriteBase + 0x28)
				local spriteZVel = memory.readwordsigned(spriteBase + 0x2a)
				local spriteHitboxW = memory.readword(spriteBase + 0x2e)
				local spriteHitboxH = memory.readword(spriteBase + 0x30)
				local spriteHitAttr = memory.readword(spriteBase + 0x34)
				local spriteHP = memory.readbyte(spriteBase + 0x36)
				local spriteInfoString = string.format("%02X($%04X)\n%03X/%04X/%d", spriteId, spriteBase % 65536, spriteTypeId, spriteHitAttr, spriteHP)

				local x = math.floor(spriteX / 256)
				local y = math.floor(spriteY / 256)
				gui.text(x - (#spriteInfoString * 2), y, spriteInfoString)
				if (x + spriteHitboxW) >= 0 and (y - spriteHitboxH) < 224 and spriteHitboxW <= 32 and spriteHitboxH <= 64 then
					gui.box(x - spriteHitboxW, y - spriteHitboxH, x + spriteHitboxW, y)
				else
					-- hmmm...
					-- print(string.format("%04X %04X", spriteHitboxW, spriteHitboxH))
				end
			end
		end
	end
end)

-- [ end of script ] -----------------------------------------------------------
-- while true do emu.frameadvance() end
