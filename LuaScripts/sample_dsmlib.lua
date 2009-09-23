
require("dsmlib")

-- xx seconds => h:mm:ss.ss
function formatseconds(seconds)
	local h, m, s
	s = seconds % 60
	m = math.floor(seconds / 60)
	h = math.floor(m / 60)
	m = m % 60
	return string.format("%d:%02d:%05.2f", h, m, s)
end

-- import dsm
local dsm = dsmImport(io.open("sample.dsm", "r"))
if dsm == nil then
	error("dsmImport returned nil.")
end

-- display general info
print("Length: "..formatseconds(#dsm.frame/dsm.frameRate))
print("Frames: "..#dsm.frame)
print("Rerecord Count: "..dsm.meta.rerecordCount)
print("ROM Used: "..dsm.meta.romSerial)

-- display all meta data
print("----")
for k, v in pairs(dsm.meta) do
	print(k.." "..tostring(v))
end

-- access to inputlogs (output what is in the first frame)
print("----")
print("First Frame:")
for k, v in pairs(dsm.frame[1]) do
	print(k.."\t"..tostring(v))
end

-- make a clone via dsmExport (Ctrl+C to escape)
print("----")
if dsmExport(dsm, io.open("dsmExport.dsm", "w")) then
	print("dsmExport succeeded.")
else
	print("dsmExport failed.")
end
