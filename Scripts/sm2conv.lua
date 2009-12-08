-- SMV <=> SM2 converter (beta!)

require("smvlib")

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

if mode == "-e" then
	print("Now Loading...")
	smvfile = io.open(dstpath, "rb")
	smv = smvImport(smvfile)
	smvfile:close()
	print("Exporting SM2...")
	sm2file = io.open(srcpath, "w")
	sm2Export(smv, sm2file)
	sm2file:close()
	print("Done")
else
	print("Now Loading...")
	sm2file = io.open(dstpath, "r")
	smv = sm2Import(sm2file)
	sm2file:close()
	print("Exporting SMV...")
	smvfile = io.open(srcpath, "wb")
	smvExport(smv, smvfile)
	smvfile:close()
	print("Done")
end
