-- SMV <=> SM2 converter (beta!)

require("smvlib")

if emu then
	if true then print("Open this script with a text editor, comment out this line, and set proper path to the variables below") return end
	mode = "-e" -- "-e" or "-d"
	smvpath = "a.smv"
	sm2path = "a.sm2"
else
	if #arg < 3 then
		print("arguments: -[ed] <smv filename> <sm2 filename>")
		return
	else
		mode = arg[1]
		smvpath = arg[2]
		sm2path = arg[3]
	end
end

if mode == "-e" then
	smvfile = io.open(smvpath, "rb")
	print("SMV importing...")
	smv = smvImport(smvfile)
	smvfile:close()
	print("SM2 exporting...")
	sm2file = io.open(sm2path, "w")
	sm2Export(smv, sm2file)
	sm2file:close()
	print("Done")
else
	print("Decoder is not implemented yet")
end
