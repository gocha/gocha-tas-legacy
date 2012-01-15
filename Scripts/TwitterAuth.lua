--[[
 Twitter Authentication script
 1. register your app to Twitter and get consumer key (please google about details)
    https://twitter.com/settings/applications
 2. set your app's consumer key into variables below, then run the script
 3. do authentication, then enter PIN from browser
 4. remember the returned oauth token and oauth token secret

 == Requirements ==
 OAuth       -- http://github.com/ignacio/LuaOAuth
   ssl.https -- http://www.inf.puc-rio.br/~brunoos/luasec/
   base64, crypto, curl, iconv -- http://luaforge.net/projects/luaaio/
]]

local OAuth = require "OAuth" -- http://github.com/ignacio/LuaOAuth
local consumer_key = "(set your app's consumer key, which is displayed in the detail page of your app)"
local consumer_secret = "(set your app's consumer key secret, which is displayed in the detail page of your app)"
local client = OAuth.new(consumer_key, consumer_secret, {
	RequestToken = "http://api.twitter.com/oauth/request_token", 
	AuthorizeUser = {"http://api.twitter.com/oauth/authorize", method = "GET"},
	AccessToken = "http://api.twitter.com/oauth/access_token"
}) 
local callback_url = "oob"
local values, response_code, response_headers, response_status_line, response_body = client:RequestToken({ oauth_callback = callback_url })
if values == nil then
	print("HTTP " .. response_code, response_body)
	return
end
local oauth_token = values.oauth_token  -- we'll need both later
local oauth_token_secret = values.oauth_token_secret
local new_url = client:BuildAuthorizationUrl({ oauth_callback = callback_url })

print("Navigate to this url with your browser, please...")
print(new_url)
print("\r\nOnce you have logged in and authorized the application, enter the PIN")

local oauth_verifier = assert(io.read("*n"))    -- read the PIN from stdin
oauth_verifier = tostring(oauth_verifier)       -- must be a string

-- now we'll use the tokens we got in the RequestToken call, plus our PIN
local client = OAuth.new(consumer_key, consumer_secret, {
	RequestToken = "http://api.twitter.com/oauth/request_token", 
	AuthorizeUser = {"http://api.twitter.com/oauth/authorize", method = "GET"},
	AccessToken = "http://api.twitter.com/oauth/access_token"
}, {
	OAuthToken = oauth_token,
	OAuthVerifier = oauth_verifier
})
client:SetTokenSecret(oauth_token_secret)

local values, err, headers, status, body = client:GetAccessToken()
if values ~= nil then
	for k, v in pairs(values) do
		print(k,v)
	end
else
	print("Authentication failed")
end
