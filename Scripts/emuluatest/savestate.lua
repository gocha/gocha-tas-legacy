count = 0
save1 = nil
save2 = nil

if movie.rerecordcounting then
	movie.rerecordcounting(false)
else
	print("movie.rerecordcounting is not available.")
end

savestate.registersave(function()
	print("save")
end)
savestate.registerload(function()
	print("load")
end)

emu.registerafter(function()
	if count == 0 then
		-- create an anonymous save
		save1 = savestate.create()
	elseif count == 50 then
		-- save, anonymous save
		savestate.save(save1)
	elseif count == 100 then
		-- load, anonymous save, twice
		savestate.load(save1)
		savestate.load(save1)
	elseif count == 150 then
		-- save, slot number directly
		savestate.save(3)
	elseif count == 200 then
		-- load, slot number directly
		savestate.load(3)
	elseif count == 250 then
		-- save, slot number via object
		save2 = savestate.create(4)
		savestate.save(save2)
	elseif count == 300 then
		-- load, slot number via object
		savestate.load(save2)
	end
	count = count + 1
end)
