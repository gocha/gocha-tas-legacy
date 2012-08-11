print("movie.play()")
movie.play("SMW.smv") -- should test with relative path

if emu.registerafter then
count = 0
emu.registerafter(function()
	count = count + 1

	if count == 300 then
		if movie.replay then
			movie.replay()
		else
			print("movie.replay is not available")
		end
	end

	if count == 900 then
		print("movie.close()")
		movie.close()
	end
end)
end
