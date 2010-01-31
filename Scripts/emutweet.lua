--[[

 Twitter + EmuLua

 Important Note:
 If you run the script on an emu which links to the lua lib statically,
 the emu will crash when it tries to post a tweet. Be careful.

 SPECIAL THANKS TO:
 http://mattn.kaoriya.net/software/lang/lua/20070524030551.htm

]]

local tw_mail = "" -- your mail address
local tw_pass = "" -- your password
local reccount_step = 1000 -- post a tweet every 'reccount_step' rerecords

-- [ twitter interfaces ] ----------------------------------------------

if not emu then
	error("This script runs under an emulua host.")
end

local http = require("socket.http")
local url = require("socket.url")
local mime = require("mime")
local lom = require("lxp.lom")
local ic = require("iconv")

-- parse text node
function get_node_text(item)
	for name, value in pairs(item) do
		if type(value) == "string" and not (name == "tag") then
			return value
		end
	end
	return nil
end

-- parse and display twitter statuses
function display_statuses(statuses)
	local t = ic.open("char", "utf-8")
	for n1, v1 in pairs(statuses) do
		if v1["tag"] == "status" then
			local date = ""
			local user = ""
			local text = ""
			for n2, v2 in pairs(v1) do
				if v2["tag"] == "created_at" then
					date = get_node_text(v2)
				elseif v2["tag"] == "text" then
					text = get_node_text(v2)
				elseif v2["tag"] == "user" then
					for n3, v3 in pairs(v2) do
						if v3["tag"] == "screen_name" then
							user = get_node_text(v3)
						end
					end
				end
			end
			-- display
			print(date)
			print(ic.iconv(t, user .. ":" .. text))
			print("")
		end
	end
end

-- update twitter status
function update_status(mail, pass, status)
	local t = ic.open("utf-8", "char")
	local update_status_url = "http://twitter.com/statuses/update.xml"
	local auth = string.format("%s:%s", mail, pass)
	local chunk = {}

	-- create url for updating status
	update_status_url = string.format("%s?status=%s", update_status_url, url.escape(ic.iconv(t, status)))

	-- send post request
	b, c = http.request {
		method = "POST",
		url = update_status_url,
		headers = { authorization = "Basic " .. (mime.b64(auth)) .. "==" },
		source = nil
	}
	if not c == 200 then
		return nil
	end
end

-- get self statuses in timeline
function get_statuses(mail, pass)
	local get_statuses_url = "http://twitter.com/statuses/friends_timeline.xml"
	local auth = string.format("%s:%s", mail, pass)
	local chunk = {}

	-- send get request
	b, c = http.request {
		method = "GET",
		url = get_statuses_url,
		headers = { authorization = "Basic " .. (mime.b64(auth)) .. "==" },
		sink = ltn12.sink.table(chunk)
	}
	if not c == 200 then
		return nil
	end
	local xml = table.concat(chunk)

	-- for debug
	--------------------------------------
	--local f = io.open('test.xml', 'r')
	--local xml = f:read('*a')
	--f:close()

	return lom.parse(xml)
end

-- [ emulua main ] -----------------------------------------------------

if tw_mail == "" or tw_pass == "" then
	error("set your twitter email address and password, it needs to be written at the beginning part of the script.")
end

local prev_reccount = -1
local prev_active = false
emu.registerbefore(function()
	-- since some emulators do not have savestate.registersave(),
	-- this 'memorial post' code is located here, instead.
	local active = movie.active()
	if active then
		local reccount = movie.rerecordcount()
		if prev_active and reccount ~= prev_reccount then
			if reccount % reccount_step == 0 then
				-- FIXME: multibyte character handling
				local filenameof = function(s)
					if s == nil then return nil end
					local i, j = 0, 0
					repeat
						j = i
						i = s:find("[/\\]", j + 1)
					until not i
					if j > 0 then
						return s:sub(j + 1)
					else
						return s
					end
				end
				local name = filenameof(movie.name())
				local msg = name .. ": rerecord count hits " .. reccount .. " now!"
				print("Tweet processing... (" .. reccount .. " rerecords)")
				update_status(tw_mail, tw_pass, msg)
			end
			prev_reccount = reccount
		end
	end
	prev_active = active
end)
