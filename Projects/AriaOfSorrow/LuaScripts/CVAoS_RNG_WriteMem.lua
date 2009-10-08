-- Castlevania: Aria of Sorrow - RNG simulator
-- This script calls RNG simulationary and write it to RAM
-- This script is written for testing luck manipulation things

local RNGAdvance = 0

gui.opacity(0.681)

if not emu then
	error("This script works under an emulua host (vba-rr)")
end

if not bit then
	require("bit")
end

-- pure 32-bit multiplier
function mul32(a, b)
	-- separate the value into two 8-bit values to prevent type casting
	local x, y, z = {}, {}, {}
	x[1] = bit.band(a, 0xff)
	x[2] = bit.band(bit.rshift(a, 8), 0xff)
	x[3] = bit.band(bit.rshift(a, 16), 0xff)
	x[4] = bit.band(bit.rshift(a, 24), 0xff)
	y[1] = bit.band(b, 0xff)
	y[2] = bit.band(bit.rshift(b, 8), 0xff)
	y[3] = bit.band(bit.rshift(b, 16), 0xff)
	y[4] = bit.band(bit.rshift(b, 24), 0xff)
	-- calculate for each bytes
	local v, c
	v = x[1] * y[1]
	z[1], c = bit.band(v, 0xff), bit.rshift(v, 8)
	v = c + x[2] * y[1] + x[1] * y[2]
	z[2], c = bit.band(v, 0xff), bit.rshift(v, 8)
	v = c + x[3] * y[1] + x[2] * y[2] + x[1] * y[3]
	z[3], c = bit.band(v, 0xff), bit.rshift(v, 8)
	v = c + x[4] * y[1] + x[3] * y[2] + x[2] * y[3] + x[1] * y[4]
	z[4], c = bit.band(v, 0xff), bit.rshift(v, 8)
	v = c + x[4] * y[2] + x[3] * y[3] + x[2] * y[4]
	z[5], c = bit.band(v, 0xff), bit.rshift(v, 8)
	v = c + x[4] * y[3] + x[3] * y[4]
	z[6], c = bit.band(v, 0xff), bit.rshift(v, 8)
	v = c + x[4] * y[4]
	z[7], z[8] = bit.band(v, 0xff), bit.rshift(v, 8)
	-- compose them and return it
	return bit.bor(z[1], bit.lshift(z[2], 8), bit.lshift(z[3], 16), bit.lshift(z[4], 24)),
	       bit.bor(z[5], bit.lshift(z[6], 8), bit.lshift(z[7], 16), bit.lshift(z[8], 24))
end

--[ AoS RNG simulator ] --------------------------------------------------------

local AoS_RN = 0

function AoS_Random()
	AoS_RN = bit.tobit(mul32(bit.rshift(AoS_RN, 8), 0x3243f6ad) + 0x1b0cb175)
	return AoS_RN
end

function AoS_RandomSeed(seed)
	AoS_RN = seed
end

function AoS_RandomLast()
	return AoS_RN
end

-- [ main code ] ---------------------------------------------------------------

local RAM = { RNG = 0x02000008 }

if RNGSeed ~= nil then
	AoS_RandomSeed(RNGSeed)
else
	AoS_RandomSeed(bit.tobit(memory.readdword(RAM.RNG)))
end
for i = 1, RNGAdvance do
	AoS_Random()
end
memory.writedword(RAM.RNG, AoS_RandomLast())
emu.message("Wrote "..string.format("%08X", AoS_RandomLast()).." (#"..RNGAdvance..")")

-- [ RNG viewer ] --------------------------------------------------------------

local RNG_Previous = 0
local RNG_NumAdvanced = -1
-- local RAM = { RNG = 0x02000008 }

emu.registerafter(function()
	local searchMax = 32

	RNG_NumAdvanced = -1
	AoS_RandomSeed(RNG_Previous)
	for i = 0, searchMax do
		if AoS_RandomLast() == bit.tobit(memory.readdword(RAM.RNG)) then
			RNG_NumAdvanced = i
			break
		end
		AoS_Random()
	end
	RNG_Previous = bit.tobit(memory.readdword(RAM.RNG))
end)

gui.register(function()
	AoS_RandomSeed(bit.tobit(memory.readdword(RAM.RNG)))
	gui.text(186, 5, string.format("NEXT:%08X", AoS_Random()))
	gui.text(186, 14, "ADVANCED:" .. ((RNG_NumAdvanced == -1) and "???" or tostring(RNG_NumAdvanced)))
end)

while true do emu.frameadvance() end
