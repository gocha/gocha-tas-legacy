local txtfile = io.open("normal.dsm")
if not txtfile then
	error("emu movie open error")
end

local dbfile = io.open("lagframe.db")
if not dbfile then
	error("db open error")
end

local line = txtfile:read("*l")
local lineno = 1
local targetlineno = tonumber(dbfile:read("*l"), 10)
while line and targetlineno do
	if lineno == targetlineno then
		targetlineno = tonumber(dbfile:read("*l"), 10)
	else
		io.write(--[[lineno, ": ", ]] line, "\n")
	end

	line = txtfile:read("*l")
	lineno = lineno + 1
end

txtfile:close()
dbfile:close()
