if emu.pause then
	emu.pause()
end

local baseaddr = 0x7e0000
local baseaddr2 = baseaddr + 0x10

if memory.isvalid then
	print(memory.isvalid(baseaddr))
else
	print("memory.isvalid is not available")
end

memory.writebyte(baseaddr, -1)  -- FF
memory.writeword(baseaddr + 4, -2)  -- FE FF
memory.writedword(baseaddr + 8, -3) -- FD FF FF FF

local rangeval = memory.readbyterange(baseaddr, 0x10)
local rangestr = ""
for i, v in ipairs(rangeval) do
	rangestr = rangestr .. string.format("%02X", v) .. " "
end
print("memory.readbyterange", rangestr)

memory.writeword(baseaddr2, 0xfeef)
memory.writeword(baseaddr2 + 2, 0xeffe)
v = memory.readbyte(baseaddr2)
print(v, string.format("%02X", v))
v = memory.readbytesigned(baseaddr2)
print(v, string.format("%02X", v))
v = memory.readword(baseaddr2)
print(v, string.format("%04X", v))
v = memory.readwordsigned(baseaddr2)
print(v, string.format("%04X", v))
v = memory.readdword(baseaddr2)
print(v, string.format("%08X", v))
v = memory.readdwordsigned(baseaddr2)
print(v, string.format("%08X", v))

-- verify the result by using memory view
