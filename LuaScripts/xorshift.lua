-- XorShift: A random number generator
-- ported to Lua by gocha

module("xorshift", package.seeall)

require "bit"

local seed128 = {}

function randomseed(s)
    for i = 0, 3 do
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
        seed128[i+1] = s
    end
end

function random_int32()
    local t = bit.bxor(seed128[1], bit.lshift(seed128[1], 11))
    seed128[1], seed128[2], seed128[3] = seed128[2], seed128[3], seed128[4]
    seed128[4] = bit.bxor(bit.bxor(seed128[4], bit.rshift(seed128[4], 19)), bit.bxor(t, bit.rshift(t, 8)))
    return seed128[4]
end

function random(...)
    -- local r = xorshift.random_int32() * (1.0/4294967296.0)
    local rtemp = xorshift.random_int32()
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
