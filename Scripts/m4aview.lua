-- AGB Music Player 2000 Monitor

if not bit then
	bit = require("bit")
end

-- ---------------------------------------------------------

-- http://lua-users.org/wiki/LuaCsv
function ParseCSVLine (line, sep)
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do 
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end

function ReadCSVFile(filename)
	local file = io.open(filename, "r")
	local line = file:read("*l")
	local csv = {}
	while line do
		table.insert(csv, ParseCSVLine(line))
		line = file:read("*l")
	end
	file:close()
	return csv
end

-- ---------------------------------------------------------

function ReadM4ADatabase(filename)
	local m4aroms_csv = ReadCSVFile(filename)
	local m4aroms = {}
	for i, csv in ipairs(m4aroms_csv) do
		local e = {
			romid = csv[1],
			songtable_addr = bit.bor(0x08000000, tonumber(csv[2], 16)),
			romfilename = csv[3],
			mplayer_addr = nil,
		}
		if csv[5] ~= nil and csv[5] ~= "" then
			e.mplayer_addr = bit.bor(0x08000000, tonumber(csv[5], 16))
		end
		m4aroms[csv[1]] = e
	end
	return m4aroms
end
local m4aroms = ReadM4ADatabase("m4aroms.csv")

function ReadRomTitle()
	return string.char(unpack(memory.readbyterange(0x080000a0, 12)))
end

function ReadRomId()
	return string.char(unpack(memory.readbyterange(0x080000ac, 4)))
end

-- ---------------------------------------------------------

function NoteNameOf(key)
	local nametable = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
	local keyname = nametable[1 + (key % 12)]
	return string.format("%-2s%2d", keyname, math.floor(key / 12) - 2)
end

-- ---------------------------------------------------------

local m4amon_mplayer_index = 0 -- (0 origin)

-- ---------------------------------------------------------

function mplayergui(x, y, mplayer_addr_base, mplayer_index)
	local mplayer_ptr_addr = mplayer_addr_base + (mplayer_index * 12)
	local mplayer_info_text = ""

	mplayer_info_text = mplayer_info_text .. string.format("MusicPlayer %d", mplayer_index)

	-- read MusicPlayerTrack* from MPlayTable
	local mplayertracktable_addr = memory.readdword(mplayer_ptr_addr + 4)
	if bit.band(mplayertracktable_addr, 0xff000000) ~= 0x03000000 then
		-- not IRAM, then
		gui.text(x, y, mplayer_info_text)
		return
	end

	mplayer_info_text = mplayer_info_text .. string.format(" [%08x -> %08x]", mplayer_ptr_addr, mplayertracktable_addr)

	for trackindex = 0, 16 - 1 do
		-- read MusicPlayerTrack
		local mplayertrack_base = mplayertracktable_addr + (trackindex * 0x50)
		local track = {
			status = memory.readbyte(mplayertrack_base),
			note = memory.readbyte(mplayertrack_base + 0x05),
			songptr = memory.readdword(mplayertrack_base + 0x40),
		}
		if track.status ~= 0 and bit.band(track.songptr, 0xfe000000) == 0x08000000 then
			mplayer_info_text = mplayer_info_text .. "\n"
			mplayer_info_text = mplayer_info_text .. string.format("Ch%02d", trackindex)
			-- mplayer_info_text = mplayer_info_text .. string.format(" %08x", track.songptr)
			mplayer_info_text = mplayer_info_text .. string.format(" %s[%3d]", NoteNameOf(track.note), track.note)
		end
	end

	gui.text(x, y, mplayer_info_text)
end

gui.register(function()
	local romid = ReadRomId()
	local m4ainfo = m4aroms[romid]
	if not m4ainfo or not m4ainfo.mplayer_addr then
		return
	end

	mplayergui(0, 0, m4ainfo.mplayer_addr, m4amon_mplayer_index)
end)
