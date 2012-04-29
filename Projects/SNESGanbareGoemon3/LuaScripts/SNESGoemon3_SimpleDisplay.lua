-- Ganbare Goemon 3 (J) Simple Memory Display for TAS work

local showReturnPos = true

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

gui.register(function()
	local fadeLevel = memory.readbyte(RAM.fadeLevel)
	if fadeLevel > 15 then fadeLevel = 0 end
	fadeLevel = fadeLevel / 15.0

	local gameState = memory.readbyte(RAM.gameState)
	if gameState == 2 or gameState == 4 then
		return
	end

	gui.opacity(opacityScale)
	for player = 1, 2 do
		local base = 0x7e0400 + ((player-1)*0xc0)
		local lineofs = (player-1) * (1*gui.fontheight)
		local xcam = bit.lshift(memory.readword(0x7e1662), 8)
		local ycam = bit.lshift(memory.readword(0x7e1672), 8)
		local x = xcam + memory.readword(base+0x08)
		local y = ycam + memory.readword(base+0x0c)
		local xret = xcam + bit.lshift(memory.readword(base+0x80), 8)
		local yret = ycam + bit.lshift(memory.readword(base+0x82), 8)

		local dump = string.format("%dP: P(%06X,%06X)", player, x, y)
		if showReturnPos and xret >= xcam and xret < (xcam + 0x10000) and yret >= ycam and yret < (ycam + 0x10000) then
			dump = dump .. string.format(" R(%06X,%06X)", xret, yret)
		end
		gui.text(1, 163+lineofs, dump)
	end
end)

-- [ end of script ] -----------------------------------------------------------
-- while true do emu.frameadvance() end
