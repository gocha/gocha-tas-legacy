-- Gakkou de Atta Kowai Hanashi
-- Text Encoder/Decoder (with no compression support)

local CHDB_FILENAME = "gakkowa.chdb"
local UNPRINTABLE_CHAR = "."

function importCharDB(filename)
	local charDB = {}
	local dbFile = io.open(filename, "rb")
	if dbFile == nil then
		return nil
	end

	for ichNative = 0, 0xffff do
		local chSJIS = dbFile:read(2)
		if chSJIS == nil or #chSJIS < 2 then
			break
		end

		charDB[ichNative] = chSJIS
	end
	dbFile:close()
	return charDB
end

function makeReversedDB(charDB)
	local reversedDB = {}
	for k, v in pairs(charDB) do
		-- 01xx is not supported in multibyte text (probably)
		if not (k >= 0x0100 and k <= 0x01ff) then
			if reversedDB[v] == nil then
				reversedDB[v] = k
			end
		end
	end
	return reversedDB
end

local charDB = importCharDB(CHDB_FILENAME)
if #arg ~= 3 then
	print("usage: gaktext [-e|-d] <input.bin> <output.bin>")
	return
end

if arg[1] == "-d" then
	local inFile = io.open(arg[2], "rb")
	if inFile == nil then
		print("Error: cannot open file: " .. arg[2])
		return
	end
	local outFile = io.open(arg[3], "wb")
	if outFile == nil then
		print("Error: cannot open file: " .. arg[3])
		inFile:close()
		return
	end

	-- decode
	while true do
		local s
		local inChar

		-- read first byte
		s = inFile:read(1)
		if s == nil then
			break
		end
		inChar = s:byte(1)

		-- multibyte
		if inChar > 0x01 and inChar < 0x10 then
			s = inFile:read(1)
			if s == nil then
				outFile:write(UNPRINTABLE_CHAR)
				break
			end
			inChar = inChar * 256 + s:byte(1)
		end

		if charDB[inChar] ~= nil then
			outFile:write(charDB[inChar])
		else
			outFile:write(UNPRINTABLE_CHAR)
		end
	end
	inFile:close()
	outFile:close()
elseif arg[1] == "-e" then
	local inFile = io.open(arg[2], "rb")
	if inFile == nil then
		print("Error: cannot open file: " .. arg[2])
		return
	end
	local outFile = io.open(arg[3], "wb")
	if outFile == nil then
		print("Error: cannot open file: " .. arg[3])
		inFile:close()
		return
	end

	-- encode
	local outLength = 0
	while true do
		local s
		local inChar
		local inCharStr
		local reversedDB = makeReversedDB(charDB)

		-- read first byte
		s = inFile:read(1)
		if s == nil then
			break
		end
		inCharStr = s
		inChar = inCharStr:byte(1)

		-- multibyte (SJIS)
		if (inChar >= 0x81 and inChar <= 0x9f) or (inChar >= 0xe0 and inChar <= 0xfc) then
			s = inFile:read(1)
			if s == nil then
				print("Error: illegal multibyte string.")
				break
			end
			local trailerChar = s:byte(1)
			if (trailerChar >= 0x40 and trailerChar <= 0x7f) or (trailerChar >= 0x80 and trailerChar <= 0xfc) then
				inCharStr = string.char(inChar, trailerChar)
				inChar = inChar * 256 + trailerChar
			else
				print("Error: illegal multibyte string.")
				break
			end
		end

		local outChar = reversedDB[inCharStr]
		if outChar == nil then
			print("Unsupported character " .. inCharStr)
			break
		end

		print(inCharStr, string.format("%04X", outChar))

		if outChar <= 0xff then
			outFile:write(string.char(outChar))
			outLength = outLength + 1
		else
			outFile:write(string.char(math.floor(outChar / 256), outChar % 256))
			outLength = outLength + 2
		end
	end
	print(string.format("Output size: %d ($%X) bytes", outLength, outLength))

	inFile:close()
	outFile:close()
else
	print("Unknown option [" .. arg[1] .. "]")
	return
end
