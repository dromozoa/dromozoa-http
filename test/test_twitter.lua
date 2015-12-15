-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-http.
--
-- dromozoa-http is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-http is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-http.  If not, see <http://www.gnu.org/licenses/>.

local base64 = require "dromozoa.commons.base64"
local json = require "dromozoa.commons.json"
local http = require "dromozoa.http"

local consumer_key = os.getenv("TWITTER_CONSUMER_KEY")
local consumer_secret = os.getenv("TWITTER_CONSUMER_SECRET")
local access_token = os.getenv("TWITTER_ACCESS_TOKEN")
local access_token_secret = os.getenv("TWITTER_ACCESS_TOKEN_SECRET")

if consumer_key == nil then
  io.stderr:write("no consumer key\n")
  os.exit()
end
if access_token == nil then
  io.stderr:write("no access token\n")
  os.exit()
end

local scheme = "https"
local host = "api.twitter.com"
local status_id = "663588769828724736"

local ua = http.user_agent():fail():verbose(false)

local uri = http.uri(scheme, host, "/1.1/statuses/show.json")
  :param("id", status_id)
  :param("trim_user", "true")
local request = http.request("GET", uri)
http.oauth(consumer_key, access_token):sign_header(request, consumer_secret, access_token_secret)
local response = assert(ua:request(request))
local result = json.decode(response.content)

assert(result.id_str == status_id)
assert(result.text:find("^不惑や知命"))
assert(result.source:find("Twitter for iPhone"))

-- local uri = http.uri(scheme, host, "/1.1/statuses/update.json")
-- local request = http.request("POST", uri)
--   :param("status", "@vaporoid ファイトだよ！")
-- http.oauth(consumer_key, access_token):sign_header(request, consumer_secret, access_token_secret)
-- print(request.oauth.signature_base_string)
-- local response = assert(ua:request(request))
