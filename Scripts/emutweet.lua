--[[

 Twitter + EmuLua
 http://d.hatena.ne.jp/GOCHA/20101022/PostTwitterByLua

 Before using this script,
 1. register your app to Twitter, then set OAuth keys to the variables below.
    for details, see TwitterAuth.lua
 2. set proper value to reccount_step, then run the script

 Important Note:
 As far as I know,
 If you run the script on an emu which links to the lua lib statically,
 the emu will crash when it tries to post a tweet. Be careful.

 SPECIAL THANKS TO:
 http://mattn.kaoriya.net/software/lang/lua/20070524030551.htm

 == Requirements ==
 dkjson      -- http://chiselapp.com/user/dhkolf/repository/dkjson/home
 OAuth       -- http://github.com/ignacio/LuaOAuth
   ssl.https -- http://www.inf.puc-rio.br/~brunoos/luasec/
   base64, crypto, curl, iconv -- http://luaforge.net/projects/luaaio/
]]

-- OAuth settings
local consumer_key = "(set your app's consumer key, which is displayed in the detail page of your app)"
local consumer_secret = "(set your app's consumer key secret, which is displayed in the detail page of your app)"
local oauth_token = "(set your oauth token, which is displayed after inputting the PIN)"
local oauth_token_secret = "(set your oauth token secret, which is displayed after inputting the PIN)"

-- Tweet settings
local reccount_step = 1000 -- post a tweet every 'reccount_step' rerecords

-- [ twitter interfaces ] ----------------------------------------------

if not emu then
	error("This script runs under an emulua host.")
end

local OAuth = require "OAuth" -- http://github.com/ignacio/LuaOAuth
local json = require "dkjson" -- http://chiselapp.com/user/dhkolf/repository/dkjson/home
local ic = require "iconv"

local charToUTF8 = ic.open("utf-8", "char")
local utf8ToChar = ic.open("char", "utf-8")

local client = OAuth.new(consumer_key, consumer_secret, {
	RequestToken = "http://api.twitter.com/oauth/request_token", 
	AuthorizeUser = {"http://api.twitter.com/oauth/authorize", method = "GET"},
	AccessToken = "http://api.twitter.com/oauth/access_token"
}, {
	OAuthToken = oauth_token,
	OAuthTokenSecret = oauth_token_secret
})

function update_status(status)
	local response_code, response_headers, response_status_line, response_body = 
		client:PerformRequest("POST", "http://api.twitter.com/1/statuses/update.json", {status = ic.iconv(charToUTF8, status)})

	if response_code >= 400 then -- client/server error?
		local response_json = json.decode(response_body)
		error(response_status_line .. " - " .. ic.iconv(utf8ToChar, response_json.error))
	end
end

-- [ emulua main ] -----------------------------------------------------

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
				-- TODO: multibyte filename support
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
				update_status(msg)
			end
			prev_reccount = reccount
		end
	end
	prev_active = active
end)
