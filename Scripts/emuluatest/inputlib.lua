emu.registerafter(function()
	local keyin = input.get()
	emu.message(tostring(keyin))
	if keyin.leftclick then
		print("leftclick")
	end
end)

-- TODO input.registerhotkey (which, func)
