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

if consumer_key == nil then
  io.stderr:write("no consumer key\n")
  os.exit()
end

local scheme = "https"
local host = "api.twitter.com"
local status_id = "663588769828724736"

local ua = http.user_agent():fail():verbose(false)

local credentials = base64.encode(consumer_key .. ":" .. consumer_secret)

local uri = http.uri(scheme, host, "/oauth2/token")
local request = http.request("POST", uri)
  :header("Authorization", "Basic " .. credentials)
  :param("grant_type", "client_credentials")
local response = assert(ua:request(request))
local result = json.decode(response.content)

-- print(result.token_type)
-- print(result.access_token)

assert(result.token_type == "bearer")
local access_token = assert(result.access_token)

local uri = http.uri(scheme, host, "/1.1/statuses/show.json")
  :param("id", status_id)
  :param("trim_user", "true")
local request = http.request("GET", uri)
  :header("Authorization", "Bearer " .. access_token)
local response = assert(ua:request(request))
local result = json.decode(response.content)

-- print(result.created_at)
-- print(result.id_str)
-- print(result.text)
-- print(result.source)
-- print(result.user.id_str)
-- print(result.retweet_count)
-- print(result.favorite_count)

assert(result.id_str == status_id)
assert(result.text:find("^不惑や知命"))
assert(result.source:find("Twitter for iPhone"))
