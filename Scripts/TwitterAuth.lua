local OAuth = require "OAuth" -- http://github.com/ignacio/LuaOAuth
local consumer_key = "(set your app's consumer key, which is displayed in the detail page of your app)"
local consumer_secret = "(set your app's consumer key secret, which is displayed in the detail page of your app)"
local client = OAuth.new(consumer_key, consumer_secret, {
	RequestToken = "http://api.twitter.com/oauth/request_token", 
	AuthorizeUser = {"http://api.twitter.com/oauth/authorize", method = "GET"},
	AccessToken = "http://api.twitter.com/oauth/access_token"
}) 
local callback_url = "oob"
local values = client:RequestToken({ oauth_callback = callback_url })
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
