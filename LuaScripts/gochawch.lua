-- Make standard memory watch list (*.wch) from conf file of gocha's memwatch.

if #arg < 2 then
	print("Usage: gochawch.lua <conf file> <ROM serial>")
	return
end

local file = io.open(arg[1], "r")
if file == nil then
	io.stderr:write("Error: unable to open conf file.\n")
	return
end

local line = file:read("*l")
local lineNo = 1
local romSerial = ""
local wch = { watch = {} }
local cComment = false
-- import
while line do
	local s

	s = string.sub(line, 1, 1)
	if string.len(s) == 0 or s == ":" or s == ";" or s == "-" then
		-- one line junk, ignore them
	elseif s == "[" then
		-- set rom serial
		romSerial = string.sub(line, 2, string.find(line, "]", 2, true) - 1)
	else
		s = string.sub(line, 1, 2)
		if s == "/*" then
			cComment = true
		elseif s == "*/" then
			cComment = false
		elseif s == "//" then
			-- one line comment, ignore them
		elseif not cComment and romSerial == arg[2] then
			if string.sub(line, 1, 1) == "$" then
				line = string.sub(line, 2)
			end

			local i = 1
			local wchEntry = {}
			for w in string.gmatch(line, "[^,]+") do
				if i == 1 then
					wchEntry.address = w
				elseif i == 2 then
					local size = tonumber(string.sub(w, 1, 1))
					local fmt = string.sub(w, 2, 2)

					if size == 1 then
						wchEntry.size = "b"
					elseif size == 2 then
						wchEntry.size = "w"
					else
						wchEntry.size = "d"
					end
					if fmt == "x" then
						fmt = "h"
					elseif fmt == "b" then
						fmt = "u"
					end
					wchEntry.format = fmt
				elseif i == 3 then
					wchEntry.comment = w
				else
					io.stderr:write("Parse error at line "..lineNo.."\n")
				end
				i = i + 1
			end
			wchEntry.wrongEndian = 0 -- correct? I dunno
			table.insert(wch.watch, wchEntry)
		end
	end

	line = file:read("*l")
	lineNo = lineNo + 1
end

file:close()

-- export
io.write("0\n") -- unknown junk which no one needs
io.write(#wch.watch.."\n")
for i = 1, #wch.watch do
	io.write(string.format("%05X", i - 1))
	io.write("\t"..wch.watch[i].address)
	io.write("\t"..wch.watch[i].size)
	io.write("\t"..wch.watch[i].format)
	io.write("\t"..wch.watch[i].wrongEndian)
	io.write("\t"..wch.watch[i].comment)
	io.write("\n")
end
