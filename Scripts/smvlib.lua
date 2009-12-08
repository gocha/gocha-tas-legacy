-- SMV (Snes9x movie) import/export functions.
-- Note: Lua cannot handle non 7-bit ASCII characters well, beware.
-- Note: Those functions don't care about corrupt files much.
-- Note: Those functions don't care about peripherals at all.

require("base64")

-- Import input sequence stored in SMV from 'file' and return an array if succeeded (nil if failed).
function smvImport(file)
	local readbyte  = function(file) return string.byte(file:read(1)) end
	local readword  = function(file) local ret = string.byte(file:read(1)); ret = ret + string.byte(file:read(1)) * 0x100; return ret end
	local readdword = function(file) local ret = string.byte(file:read(1)); ret = ret + string.byte(file:read(1)) * 0x100; ret = ret + string.byte(file:read(1)) * 0x10000; ret = ret + string.byte(file:read(1)) * 0x1000000; return ret end
	local bitof = function(x, n) return math.floor(x/(2^n)) % 2 end
	local removenull8 = function(s)
		local pos = s:find(string.char(0), 1, true) -- utf-16 null
		if pos then
			return (pos > 1 and s:sub(1, pos - 1) or "")
		else
			return s
		end
	end
	local removenull16 = function(s)
		local pos = s:find(string.char(0, 0), 1, true) -- utf-16 null
		if pos then
			if pos % 2 ~= 0 then pos = pos + 1 end
			return (pos > 1 and s:sub(1, pos - 1) or "")
		else
			return s
		end
	end
	local removepaddings = function(s,c)
		local pos = #s + 1
		while pos > 1 and s:sub(pos-1,pos-1):byte() == c do
			pos = pos - 1
		end
		if pos == 1 then
			return ""
		elseif pos <= #s then
			return s:sub(1,pos-1)
		end
	end
	local forcerawcomment = false
	local base64katakana = true

	if file == nil then
		return nil
	end

	local smv = { frame = {}, meta = {} }
	local flags

	-- 000 4-byte signature: 53 4D 56 1A "SMV\x1A"
	if file:read(4) ~= string.char(0x53, 0x4d, 0x56, 0x1a) then
		return nil
	end
	-- 004 4-byte little-endian unsigned int: version number, must be 1
	local version = readdword(file)
	if version == 2 or version == 3 then
		error("SMV version " .. version .. " is not supported")
	end
	smv.meta.emuVersion = version
	-- 008 4-byte little-endian integer: movie "uid"
	smv.meta.guid = readdword(file)
	-- 00C 4-byte little-endian unsigned int: rerecord count
	smv.meta.rerecordCount = readdword(file)
	-- 010 4-byte little-endian unsigned int: number of frames
	local numFrames = readdword(file)
	-- 014 1-byte flags "controller mask"
	flags = readbyte(file)
	local controllers = {}
	for player = 1, 5 do
		if bitof(flags, player-1) ~= 0 then
			table.insert(controllers, player)
		end
	end
	if #controllers == 0 then
		error("No controllers used")
	end
	-- 015 1-byte flags "movie options"
	flags = readbyte(file)
	local hasSavestate = (bitof(flags, 0) == 0)
	smv.meta.palFlag = bitof(flags, 1)
	-- 016 1-byte flags "sync options"
	flags = readbyte(file)
	smv.meta.clearFastROM = bitof(flags, 0)
	-- 017 1-byte flags "sync options"
	flags = readbyte(file)
	smv.meta.useWIPAPUTiming = bitof(flags, 1)
	smv.meta.allowLeftRight = bitof(flags, 2)
	smv.meta.envelopeHeightReading = bitof(flags, 3)
	smv.meta.fakeMute = bitof(flags, 4)
	smv.meta.syncSound = bitof(flags, 5)
	smv.meta.cpuShutdown = bitof(flags, 7)
	local hasSyncInfo = (bitof(flags, 0) ~= 0)
	local hasROMInfo = (bitof(flags, 6) ~= 0)
	-- 018 4-byte little-endian unsigned int: offset to the savestate inside file
	local saveStateOffset = readdword(file)
	-- 01C 4-byte little-endian unsigned int: offset to the controller data inside file
	local controllerDataOffset = readdword(file)
	if version >= 4 then
		error("TODO: handle additional header in 1.51")

		-- 020 4-byte little-endian unsigned int: number of input samples, primarily for peripheral-using games
		-- 024 2 1-byte unsigned ints: what type of controller is plugged into ports 1 and 2 respectively: 0=NONE, 1=JOYPAD, 2=MOUSE, 3=SUPERSCOPE, 4=JUSTIFIER, 5=MULTITAP
		-- 026 4 1-byte signed ints: controller IDs of port 1, or -1 for unplugged
		-- 02A 4 1-byte signed ints: controller IDs of port 2, or -1 for unplugged
		-- 02E 18 bytes: reserved for future use
	end

	if not hasSyncInfo then
		--[[
		smv.meta.clearFastROM = false
		smv.meta.useWIPAPUTiming = false
		smv.meta.allowLeftRight = false
		smv.meta.envelopeHeightReading = false
		smv.meta.fakeMute = true
		smv.meta.syncSound = true
		smv.meta.cpuShutdown = false
		]]
	end
	local headerSize
	if version == 1 then
		smv.meta.cpuShutdown = nil
		headerSize = 0x20
	elseif version > 1 then
		smv.meta.useWIPAPUTiming = nil
		smv.meta.clearFastROM = nil
		headerSize = 0x40
	end

	local comment = file:read(saveStateOffset - (hasSyncInfo and 30 or 0) - headerSize)
	if forcerawcomment then
		smv.meta.comment = "base64:" .. base64.enc(comment)
	else
		-- truncate glitchy noises etc
		comment = removenull16(comment)
		-- detect if the comment is a simple ASCII string
		local isascii = true
		for i = 1, #comment, 2 do
			if comment:byte(i) < 0x20 or comment:byte(i) > 0x7e or (i < #comment and comment:byte(i+1) ~= 0) then
				isascii = false
				break
			end
		end
		-- decode it to ASCII if possible
		if isascii then
			comment = comment:gsub("%z", "")
			smv.meta.comment = comment
		else
			smv.meta.comment = "base64:" .. base64.enc(comment)
		end
	end

	if hasROMInfo then
		-- 000 3 bytes of zero padding: 00 00 00
		file:read(3)
		-- 003 4-byte integer: CRC32 of the ROM
		smv.meta.romChecksum = readdword(file)
		-- 007 23-byte ascii string
		smv.meta.romSerial = file:read(23)
		-- truncate zero paddings
		smv.meta.romSerial = removenull8(smv.meta.romSerial)
		-- encode to base64 if needed
		if not smv.meta.romSerial:match("^[ -~]*$") then
			if base64katakana or not smv.meta.romSerial:match("^[ -~"..string.char(0xa0).."-"..string.char(0xdf).."]+$") then
				smv.meta.romSerial = "base64:" .. base64.enc(smv.meta.romSerial)
			end
		end
	end

	-- SRAM / savestate
	local saveStateSize = controllerDataOffset - saveStateOffset
	if saveStateSize < 0 then
		error("SMV - Invalid data offsets")
	end
	if hasSavestate then
		smv.meta.savestate = "base64:" .. base64.enc(file:read(saveStateSize))
	else
		smv.meta.sram = "base64:" .. base64.enc(file:read(saveStateSize))
	end

	-- joypad data
	local buttonMappings = { "b0", "b1", "b2", "b3", "R", "L", "X", "A", "right", "left", "down", "up", "start", "select", "Y", "B" }
	for f = 1, numFrames do
		smv.frame[f] = {}
		smv.frame[f].joypad = {}
		-- read joypad data
		for pad = 1, #controllers do
			local padId = controllers[pad]
			flags = readword(file)
			smv.frame[f].joypad[padId] = {}
			smv.frame[f].reset = (flags == 0xffff)
			if smv.frame[f].reset then
				for b = 1, #buttonMappings do
					if buttonMappings[b] ~= "" then
						smv.frame[f].joypad[padId][buttonMappings[b]] = false
					end
				end
			else
				for b = 1, #buttonMappings do
					if buttonMappings[b] ~= "" then
						smv.frame[f].joypad[padId][buttonMappings[b]] = (bitof(flags, b - 1) ~= 0)
					end
				end
			end
		end
	end

	smv.frameRate = 60.0
	return smv
end

-- Export SM2 to 'file'
function sm2Export(sm2, file)
	if file == nil then
		return false
	end

	for k, v in pairs(sm2.meta) do
		if type(v) == "string" then
			file:write(k.." "..v.."\n")
		elseif k == "romChecksum" or k == "guid" then
			file:write(k.." "..string.format("%08X", v).."\n")
		else
			file:write(k.." "..tostring(v).."\n")
		end
	end

	for pad = 1, 5 do
		file:write("controller"..pad.." "..(sm2.frame[1].joypad[pad] ~= nil and 1 or 0).."\n")
	end

	for f = 1, #sm2.frame do
		local buttonMappingsR = { "", "left", "up", "right", "down", "b1", "A", "B", "Y", "X", "b2", "L", "R", "b3", "start", "select" }
		local buttonMappingsW = { "", "L", "U", "R", "D", "0", "A", "B", "Y", "X", "1", "W", "E", "2", "S", "s" }
		-- local buttonMappingsW = { "-", "<", "^", ">", "v", "0", "A", "B", "Y", "X", "1", "L", "R", "2", "S", "s" }

		local cmdMappings = { "reset" }
		local cmd

		cmd = 0
		for i = 0, #cmdMappings - 1 do
			local bitf = math.pow(2, i) -- (1 << i)
			if sm2.frame[f][ cmdMappings[i+1] ] then
				cmd = cmd + bitf
			end
		end

		file:write("|"..cmd.."|")
		for pad = 1, 5 do
			if sm2.frame[f].joypad[pad] ~= nil then
				for i = 1, #buttonMappingsW do
					if buttonMappingsR[i] ~= "" then
						file:write((sm2.frame[f].joypad[pad][ buttonMappingsR[i] ] and buttonMappingsW[i] or "."))
					end
				end
				file:write("|")
			end
		end
		file:write("\n")
	end

	return true
end
