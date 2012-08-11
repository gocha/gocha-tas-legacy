local joyget = joypad.get
-- get, getdown, getup
-- peek, peekdown, peekup

emu.registerbefore(function()
	local t = joyget()
	emu.message(t)

	-- redirect test
	joypad.set(t)
end)

-- 1. joypad.peek must return user input, regardless of movie activity
-- 2. joypad.get must return movie input, if movie.active()
