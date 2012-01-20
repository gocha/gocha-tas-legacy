local OAuth = require "OAuth" -- http://github.com/ignacio/LuaOAuth
local json = require "dkjson" -- http://chiselapp.com/user/dhkolf/repository/dkjson/home
local ic = require "iconv"
local consumer_key = "(set your app's consumer key, which is displayed in the detail page of your app)"
local consumer_secret = "(set your app's consumer key secret, which is displayed in the detail page of your app)"
local oauth_token = "(set your oauth token, which is displayed after inputting the PIN)"
local oauth_token_secret = "(set your oauth token secret, which is displayed after inputting the PIN)"

local table, string, os, print = table, string, os, print
local error, assert = error, assert
local pairs, tostring, tonumber, type, next, setmetatable = pairs, tostring, tonumber, type, next, setmetatable
local math = math

module((...))

local client = OAuth.new(consumer_key, consumer_secret, {
	RequestToken = "http://api.twitter.com/oauth/request_token", 
	AuthorizeUser = {"http://api.twitter.com/oauth/authorize", method = "GET"},
	AccessToken = "http://api.twitter.com/oauth/access_token"
}, {
	OAuthToken = oauth_token,
	OAuthTokenSecret = oauth_token_secret
})
local charToUTF8 = ic.open("utf-8", "char")
local utf8ToChar = ic.open("char", "utf-8")

function Post(status)
	local response_code, response_headers, response_status_line, response_body = 
		client:PerformRequest("POST", "http://api.twitter.com/1/statuses/update.json", {status = ic.iconv(charToUTF8, status)})

	if tonumber(response_code) >= 400 then -- client/server error (note that response_code can be string when the client machine is offline)
		local response_json = json.decode(response_body)
		print(response_status_line .. " - " .. ic.iconv(utf8ToChar, response_json.error))
		--[[
		print("response_code", response_code)
		print("response_status_line", response_status_line)
		for k,v in pairs(response_headers) do print(k,v) end
		print("response_body", response_body)
		]]
	end
end
