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
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha1 = require "dromozoa.commons.sha1"
local http = require "dromozoa.http"
local oauth = require "dromozoa.http.oauth"

local ua = http.user_agent():fail():verbose()

local scheme = "https"
local host = "api.twitter.com"
local consumer_secret = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
local oauth_token_secret = "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"

local uri = http.uri(scheme, host, "/1/statuses/update.json")
  :param("include_entities", "true")
local request = http.request("POST", uri)
  :encode(http.uri.encode)
  :param("status", "Hello Ladies + Gentlemen, a signed OAuth request!")
request:build()
assert(request.content == [[
status=Hello%20Ladies%20%2B%20Gentlemen%2C%20a%20signed%20OAuth%20request%21]])

local params = sequence()
params:push({ "oauth_consumer_key", "xvz1evFS4wEEPTGEFPHBog" })
params:push({ "oauth_nonce", "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg" })
params:push({ "oauth_signature_method", "HMAC-SHA1" })
params:push({ "oauth_timestamp", "1318622958" })
params:push({ "oauth_token", "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb" })
params:push({ "oauth_version", "1.0" })
for param in request.uri.query.params:each() do
  params:push({ param[1], param[2] })
end
for param in request.params:each() do
  params:push({ param[1], param[2] })
end

for param in params:each() do
  param[1] = http.uri.encode(param[1])
  param[2] = http.uri.encode(param[2])
end
params:sort(function (a, b) return a[1] < b[1] end)

local out = sequence_writer()
local first = true
for param in params:each() do
  if first then
    first = false
  else
    out:write("&")
  end
  out:write(param[1], "=", param[2])
end
local parameter_string = out:concat()
assert(parameter_string == [[
include_entities=true&oauth_consumer_key=xvz1evFS4wEEPTGEFPHBog&oauth_nonce=kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1318622958&oauth_token=370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb&oauth_version=1.0&status=Hello%20Ladies%20%2B%20Gentlemen%2C%20a%20signed%20OAuth%20request%21]])

local signature_base_string
    = request.method:upper()
    .. "&"
    .. http.uri.encode(request.uri.scheme .. "://" .. request.uri.authority .. request.uri.path)
    .. "&"
    .. http.uri.encode(parameter_string)
assert(signature_base_string == [[
POST&https%3A%2F%2Fapi.twitter.com%2F1%2Fstatuses%2Fupdate.json&include_entities%3Dtrue%26oauth_consumer_key%3Dxvz1evFS4wEEPTGEFPHBog%26oauth_nonce%3DkYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1318622958%26oauth_token%3D370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb%26oauth_version%3D1.0%26status%3DHello%2520Ladies%2520%252B%2520Gentlemen%252C%2520a%2520signed%2520OAuth%2520request%2521]])

local signing_key = http.uri.encode(consumer_secret) .. "&" .. http.uri.encode(oauth_token_secret)
assert(signing_key == [[
kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw&LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE]])

local oauth_signature = base64.encode(sha1.hmac(signing_key, signature_base_string, "bin"))
assert(oauth_signature == [[
tnnArxj06cWHq44gCs1OSKk/jLY=]])

local a = oauth():reset()
-- print(json.encode(a))
print(a.oauth_nonce)
