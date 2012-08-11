local joyget = joypad.getdown
-- get, getdown, getup
-- peek, peekdown, peekup

emu.registerbefore(function()
	local t = joyget()
	emu.message(t)

	-- redirect test
	joypad.set(t)

	local t2 = joyget()
	-- must be t == t2, regardless of movie activity
	local roundtripSuccess = true
	for k in pairs(t) do
		if t[k] ~= t2[k] then
			roundtripSuccess = false
			break
		end
	end
	for k in pairs(t2) do
		if t[k] ~= t[k] then
			roundtripSuccess = false
			break
		end
	end
	if not roundtripSuccess then
		emu.message("round-trip get/set error")
	end
end)

-- 1. joypad.peek must return user input, regardless of movie activity
-- 2. joypad.get must return movie input, if movie.active()
