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
local clone = require "dromozoa.commons.clone"
local random_bytes = require "dromozoa.commons.random_bytes"
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha1 = require "dromozoa.commons.sha1"
local uri = require "dromozoa.commons.uri"
local uri_query = require "dromozoa.http.uri_query"

local class = {}

function class.new(oauth_consumer_key, oauth_token)
  return {
    oauth_consumer_key = oauth_consumer_key;
    oauth_token = oauth_token;
  }
end

function class:param(name, value)
  self.name = value
  return self
end

function class:reset(oauth_timestamp, oauth_nonce)
  if oauth_timestamp == nil then
    oauth_timestamp = os.time()
  end
  if oauth_nonce == nil then
    oauth_nonce = base64.encode_url(random_bytes(32))
  end
  self.oauth_timestamp = oauth_timestamp
  self.oauth_nonce = oauth_nonce
  return self
end

function class:build(request)
  request:build()
  if request.oauth == nil then
    request.oauth = {}
  end
  return self
end

function class:make_parameter_string(request)
  local this = request.oauth

  local oauth_params = uri_query()
    :param({
      oauth_callback = self.oauth_callback;
      oauth_consumer_key = self.oauth_consumer_key;
      oauth_nonce = self.oauth_nonce;
      oauth_signature_method = "HMAC-SHA1";
      oauth_timestamp = self.oauth_timestamp;
      oauth_token = self.oauth_token;
      oauth_version = "1.0";
    })
    :param(request.uri.query)
    :param(request.form)

  this.oauth_params = oauth_params:sort()
  this.parameter_string = oauth_params:build()
  return self
end

function class:make_signature_base_string(request)
  local this = request.oauth
  local url = clone(request.uri)
  url.query = uri_query()
  this.signature_base_string = sequence_writer()
    :write(request.method:upper())
    :write("&")
    :write(uri.encode(url))
    :write("&")
    :write(uri.encode(this.parameter_string))
    :concat()
  return self
end

function class:make_signature(request, oauth_consumer_secret, oauth_token_secret)
  if oauth_token_secret == nil then
    oauth_token_secret = ""
  end
  local this = request.oauth
  local signing_key = uri.encode(oauth_consumer_secret) .. "&" .. uri.encode(oauth_token_secret)
  this.signature = base64.encode(sha1.hmac(signing_key, this.signature_base_string, "bin"))
  return self
end

function class:make_header(request)
  local this = request.oauth
  local oauth_params = sequence()

  if self.oauth_callback ~= nil then
    oauth_params:push({ "oauth_callback", self.oauth_callback })
  end
  oauth_params
    :push({ "oauth_consumer_key", uri.encode(self.oauth_consumer_key) })
    :push({ "oauth_nonce", uri.encode(self.oauth_nonce) })
    :push({ "oauth_signature", uri.encode(this.signature) })
    :push({ "oauth_signature_method", "HMAC-SHA1" })
    :push({ "oauth_timestamp", uri.encode(self.oauth_timestamp) })
  if self.oauth_token ~= nil then
    oauth_params:push({ "oauth_token", self.oauth_token })
  end
  oauth_params:push({ "oauth_version", "1.0" })

  local out = sequence_writer():write("OAuth ")
  local first = true
  for param in oauth_params:each() do
    if first then
      first = false
    else
      out:write(", ")
    end
    out:write(param[1], "=\"", param[2], "\"")
  end

  local authorization = out:concat()
  this.authorization = authorization
  request:header("Authorization", authorization)
  return self
end

function class:sign_header(request, oauth_consumer_secret, oauth_token_secret)
  return self
    :reset()
    :build(request)
    :make_parameter_string(request)
    :make_signature_base_string(request)
    :make_signature(request, oauth_consumer_secret, oauth_token_secret)
    :make_header(request)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, oauth_consumer_key, oauth_token)
    return setmetatable(class.new(oauth_consumer_key, oauth_token), metatable)
  end;
})
