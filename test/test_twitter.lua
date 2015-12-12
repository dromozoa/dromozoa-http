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

local http = require "dromozoa.http"
local base16 = require "dromozoa.commons.base16"
local base64 = require "dromozoa.commons.base64"

local ua = http.user_agent():fail():verbose()

local scheme = "https"
local host = "api.twitter.com"

local uri = http.uri(scheme, "/1/statuses/update.json")
  :param("include_entities", "true")
local request = http.request("POST", uri)
  :param("status", "Hello Ladies + Gentlemen, a signed OAuth request!")
request:build()
print(request.content)

local handle = assert(io.open("/dev/urandom", "rb"))
local random = handle:read(32)
handle:close()

print(base64.encode(random))

-- OAuth oauth_consumer_key="xvz1evFS4wEEPTGEFPHBog", oauth_nonce="kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg", oauth_signature="tnnArxj06cWHq44gCs1OSKk%2FjLY%3D", oauth_signature_method="HMAC-SHA1", oauth_timestamp="1318622958", oauth_token="370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb", oauth_version="1.0"

--[[

]]

-- POST
-- https%3A%2F%2Fapi.twitter.com%2F1%2Fstatuses%2Fupdate.json
-- https://api.twitter.com/1/statuses/update.json
-- include_entities%3Dtrue%26oauth_consumer_key%3Dxvz1evFS4wEEPTGEFPHBog%26oauth_nonce%3DkYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1318622958%26oauth_token%3D370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb%26oauth_version%3D1.0%26status%3DHello%2520Ladies%2520%252B%2520Gentlemen%252C%2520a%2520signed%2520OAuth%2520request%2521

-- include_entities=true
-- oauth_consumer_key=xvz1evFS4wEEPTGEFPHBog
-- oauth_nonce=kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg
-- oauth_signature_method=HMAC-SHA1
-- oauth_timestamp=1318622958
-- oauth_token=370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb
-- oauth_version=1.0
-- status=Hello%20Ladies%20%2B%20Gentlemen%2C%20a%20signed%20OAuth%20request%21

