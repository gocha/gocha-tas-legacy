-- SMV <=> SM2 converter (beta!)

require("smvlib")

local mode, dstpath, srcpath
if emu then
	if true then print("Open this script with a text editor, comment out this line, and set proper path to the variables below") return end
	mode = "-e" -- "-e" or "-d"
	dstpath = "a.smv"
	srcpath = "a.sm2"
else
	if #arg < 3 then
		print("arguments: -[ed] <smv filename> <sm2 filename>")
		return
	else
		mode = arg[1]
		dstpath = arg[2]
		srcpath = arg[3]
	end
end

local smvfile, sm2file
local smv, succeeded
if mode == "-e" then
	print("Now Loading...")
	smvfile = io.open(dstpath, "rb")
	smv = smvImport(smvfile)
	smvfile:close()
	if not smv then
		io.stderr:write("Error: Failed to load a movie.\n")
		return
	end
	print("Exporting SM2...")
	sm2file = io.open(srcpath, "w")
	succeeded = sm2Export(smv, sm2file)
	sm2file:close()
	if succeeded then
		print("Done")
	else
		io.stderr:write("Error: Failed to export a movie.\n")
	end
else
	print("Now Loading...")
	sm2file = io.open(dstpath, "r")
	smv = sm2Import(sm2file)
	sm2file:close()
	if not smv then
		io.stderr:write("Error: Failed to load a movie.\n")
		return
	end
	print("Exporting SMV...")
	smvfile = io.open(srcpath, "wb")
	succeeded = smvExport(smv, smvfile)
	smvfile:close()
	if succeeded then
		print("Done")
	else
		io.stderr:write("Error: Failed to export a movie.\n")
	end
end
