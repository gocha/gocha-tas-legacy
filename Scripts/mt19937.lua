-- Mersenne Twister: A random number generator
-- ported to Lua by gocha, based on mt19937ar.c

module("mt19937", package.seeall)

require "bit"

-- Period parameters
local N = 624
local M = 397
local MATRIX_A = 0x9908b0df   -- constant vector a
local UPPER_MASK = 0x80000000 -- most significant w-r bits
local LOWER_MASK = 0x7fffffff -- least significant r bits

local mt = {}     -- the array for the state vector
local mti = N + 1 -- mti==N+1 means mt[N] is not initialized

-- initializes mt[N] with a seed
function randomseed(s)
    s = bit.band(s, 0xffffffff)
    mt[1] = s
    for i = 1, N - 1 do
        -- s = 1812433253 * (bit.bxor(s, bit.rshift(s, 30))) + i
        s = bit.bxor(s, bit.rshift(s, 30))
        local s_lo = bit.band(s, 0xffff)
        local s_hi = bit.rshift(s, 16)
        local s_lo2 = bit.band(1812433253 * s_lo, 0xffffffff)
        local s_hi2 = bit.band(1812433253 * s_hi, 0xffff)
        s = bit.bor(bit.lshift(bit.rshift(s_lo2, 16) + s_hi2, 16),
            bit.band(s_lo2, 0xffff))
        -- s = bit.band(s + i, 0xffffffff)
        local s_lim = -bit.tobit(s)
        -- assumes i<2^31
        if (s_lim > 0 and s_lim <= i) then
            s = i - s_lim
        else
            s = s + i
        end
        mt[i+1] = s
        -- See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier.
        -- In the previous versions, MSBs of the seed affect
        -- only MSBs of the array mt[].
        -- 2002/01/09 modified by Makoto Matsumoto
    end
    mti = N
end

local mag01 = { 0, MATRIX_A }   -- mag01[x] = x * MATRIX_A  for x=0,1

-- generates a random number on [0,0xffffffff]-interval
function random_int32()
    local y

    if (mti >= N) then -- generate N words at one time
        local kk

        if (mti == N + 1) then -- if init_genrand() has not been called,
            mt19937.randomseed(5489) -- a default initial seed is used
        end

        for kk = 1, N - M do
            y = bit.bor(bit.band(mt[kk], UPPER_MASK), bit.band(mt[kk+1], LOWER_MASK))
            mt[kk] = bit.bxor(mt[kk+M], bit.rshift(y, 1), mag01[1 + bit.band(y, 1)])
        end
        for kk = N - M + 1, N - 1 do
            y = bit.bor(bit.band(mt[kk], UPPER_MASK), bit.band(mt[kk+1], LOWER_MASK))
            mt[kk] = bit.bxor(mt[kk+(M-N)], bit.rshift(y, 1), mag01[1 + bit.band(y, 1)])
        end
        y = bit.bor(bit.band(mt[N], UPPER_MASK), bit.band(mt[1], LOWER_MASK))
        mt[N] = bit.bxor(mt[M], bit.rshift(y, 1), mag01[1 + bit.band(y, 1)])

        mti = 0
    end

    y = mt[mti+1]
    mti = mti + 1

    -- Tempering
    y = bit.bxor(y, bit.rshift(y, 11))
    y = bit.bxor(y, bit.band(bit.lshift(y, 7), 0x9d2c5680))
    y = bit.bxor(y, bit.band(bit.lshift(y, 15), 0xefc60000))
    y = bit.bxor(y, bit.rshift(y, 18))

    return y
end

function random(...)
    -- local r = mt19937.random_int32() * (1.0/4294967296.0)
    local rtemp = mt19937.random_int32()
    local r = (bit.band(rtemp, 0x7fffffff) * (1.0/4294967296.0)) + (bit.tobit(rtemp) < 0 and 0.5 or 0)
    local arg = {...}
    if #arg == 0 then
        return r
    elseif #arg == 1 then
        local u = math.floor(arg[1])
        if 1 <= u then
            return math.floor(r*u)+1
        else
            error("bad argument #1 to 'random' (internal is empty)")
        end
    elseif #arg == 2 then
        local l, u = math.floor(arg[1]), math.floor(arg[2])
        if l <= u then
            return math.floor((r*(u-l+1))+l)
        else
            error("bad argument #2 to 'random' (internal is empty)")
        end
    else
        error("wrong number of arguments")
    end
end
