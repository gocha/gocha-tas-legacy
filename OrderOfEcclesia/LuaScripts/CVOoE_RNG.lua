-- Castlevania: Order of Ecclesia - RNG simulator
-- This script runs on both of normal lua host and emulua host (desmume)

if emu then
	-- Use desmume r2871+, or it'll return wrong value.
	if OR(0xffffffff, 0) ~= -1 then
		--require("bit")
		error("Bad bitwise operation detected. Use newer version to solve the problem.")
	else
		bit = {}
		bit.band = AND
		bit.bor  = OR
		bit.bxor = XOR
		function bit.tobit(num) return AND(num, 0xffffffff) end
		function bit.lshift(num, shift) return SHIFT(num, -shift) end
		function bit.rshift(num, shift) return SHIFT(num,  shift) end
		function bit.arshift(num, shift) return math.floor(num / SHIFT(1, -shift)) end
	end
else
	require("bit")
end

-- pure 32-bit multiplier
function mul32(a, b)
	a = bit.tobit(a)
	b = bit.tobit(b)
	-- separate the value into two 16-bit values to prevent type casting
	local b_lo = bit.band(b, 0xffff)
	local b_hi = bit.rshift(b, 16)
	-- compute each multiplication
	local v_lo = bit.tobit(a * b_lo)
	local v_hi = bit.band(a * b_hi, 0xffff)
	-- compose them
	local v = bit.bor(
		bit.lshift(bit.rshift(v_lo, 16) + v_hi, 16), -- higher 16-bit
		bit.band(v_lo, 0xffff) -- lower 16-bit
	)
	-- return it
	return bit.tobit(v)
end

--[ OoE RNG simulator ] --------------------------------------------------------

local OoE_RN = 0

function OoE_Random()
	OoE_RN = bit.tobit(mul32(bit.arshift(OoE_RN, 8), 0x3243f6ad) + 0x1b0cb175)
	return OoE_RN
end

function OoE_RandomSeed(seed)
	OoE_RN = seed
end

function OoE_RandomLast()
	return OoE_RN
end

--------------------------------------------------------------------------------
if not emu then
-- [ main code for normal lua host ] -------------------------------------------

local numsToView = 128
local searchSpecifiedVal = false
local valToSearch

if #arg >= 1 then
	OoE_RandomSeed(tonumber(arg[1]))
	if #arg >= 2 then
		numsToView = tonumber(arg[2])
		if #arg >= 3 then
			searchSpecifiedVal = true
			valToSearch = tonumber(arg[3])
		end
	end
else
	io.write("Input the intial value of RNG: ")
	OoE_RandomSeed(io.read("*n"))
end

for i = 1, numsToView do
	io.write(string.format("%08X", OoE_RandomLast()))
	if i % 8 == 0 then
		io.write("\n")
	else
		io.write(" ")
	end
	if searchSpecifiedVal and OoE_RandomLast() == valToSearch then
		if i % 8 ~= 0 then
			io.write("\n")
		end
		break
	end
	OoE_Random()
end

--------------------------------------------------------------------------------
else
-- [ main code for emulua host ] -----------------------------------------------

local RNG_Previous = 0
local RNG_NumAdvanced = -1
local RAM = { RNG = 0x021389c0 }

emu.registerafter(function()
	local searchMax = 100

	RNG_NumAdvanced = -1
	OoE_RandomSeed(RNG_Previous)
	for i = 0, searchMax do
		if OoE_RandomLast() == memory.readdword(RAM.RNG) then
			RNG_NumAdvanced = i
			break
		end
		OoE_Random()
	end
	RNG_Previous = memory.readdword(RAM.RNG)
end)

gui.register(function()
	OoE_RandomSeed(memory.readdword(RAM.RNG))
	agg.text(116, 5, string.format("NEXT:%08X", OoE_Random()))
	agg.text(116, 26, "ADVANCED:" .. ((RNG_NumAdvanced == -1) and "???" or tostring(RNG_NumAdvanced)))
end)

--------------------------------------------------------------------------------
end
