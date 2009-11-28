-- remove all lag frame input from text-based movie.

if not emu then
	if #arg < 2 then
		print("arguments: <key movie file> <lag frame database file>")
		return
	end
	txtpath = arg[1]
	dbpath = arg[2]
	outfile = io.stdout
else
	txtpath = "a.dsm"
	dbpath = "lag.db"
	outfile = io.open("out.dsm", "w")
	if outfile == nil then
		error("output open error")
	end
end

local txtfile = io.open(txtpath)
if not txtfile then
	error("emu movie open error")
end

local dbfile = io.open(dbpath)
if not dbfile then
	error("db open error")
end

function getNextFrameInput(file)
	local line
	while true do
		line = file:read("*l")
		if line == nil then
			return nil
		end
		if string.sub(line, 1, 1) == "|" then
			break
		else
			outfile:write(line, "\n")
		end
	end
	return line
end

local line = getNextFrameInput(txtfile)
local prevline = line
local nextline = getNextFrameInput(txtfile)
local lineno = 1
local targetlineno = tonumber(dbfile:read("*l"), 10)
while line do
	if targetlineno and lineno == targetlineno then
		-- outfile:write("|0|.............000 000 0|\n")
		targetlineno = tonumber(dbfile:read("*l"), 10)
	else
		outfile:write(--[[lineno, ": ", ]] line, "\n")
	end

	prevline = line
	line = nextline
	nextline = getNextFrameInput(txtfile)
	lineno = lineno + 1
end

txtfile:close()
dbfile:close()
if outfile ~= io.stdout then
	outfile:close()
end
