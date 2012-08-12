--require "lfs"
--print(lfs.currentdir())

file = io.open("cwdtest.lua", "r")
if file then
	print("Success - current directory is set to script location")
	file:close()
else
	print("Failed - current directory is NOT set to script location")
end
