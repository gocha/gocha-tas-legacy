-- Castlevania: Order of Ecclesia - RNG simulator
-- This script runs on both of normal lua host and emulua host (desmume)

if emu then
	-- Use desmume r2871+, or it'll return wrong value.
	if OR(0xffffffff, 0) ~= -1 then
		error("Bit operation")
	end

	bit = {}
	bit.band = AND
	bit.bor  = OR
	bit.bxor = XOR
	function bit.tobit(num) return AND(num, 0xffffffff) end
	function bit.lshift(num, shift) return SHIFT(num, -shift) end
	function bit.rshift(num, shift) return SHIFT(num,  shift) end
	function bit.arshift(num, shift) return math.floor(num / SHIFT(1, -shift)) end
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

if #arg >= 1 then
	OoE_RandomSeed(tonumber(arg[1]))
	if #arg >= 2 then
		numsToView = tonumber(arg[2])
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
	OoE_Random()
end

--------------------------------------------------------------------------------
else
-- [ main code for emulua host ] -----------------------------------------------

gui.register(function()
	OoE_RandomSeed(memory.readdword(0x021389c0))
	agg.text(116, 5, string.format("NEXT:%08X", OoE_Random()))
end)

--------------------------------------------------------------------------------
end
