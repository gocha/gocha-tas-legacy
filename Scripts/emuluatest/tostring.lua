temp = 0
function func()
	emu.message(temp)
	gui.text(1, 1, 1)
	if temp < 10 then
		print({ 1, 2, 3 })
		print(1, temp)
		print(nil)
		temp = temp + 1
	end
end
func()
if emu.registerbefore then
	emu.registerbefore(func)
end
if emu.registerafter then
	emu.registerafter(func)
end
if savestate.registersave then
	savestate.registersave(func)
end
if savestate.registerload then
	savestate.registerload(func)
end
