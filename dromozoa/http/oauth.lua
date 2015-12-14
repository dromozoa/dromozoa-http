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
local random_bytes = require "dromozoa.commons.random_bytes"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha1 = require "dromozoa.commons.sha1"
local parameters = require "dromozoa.http.parameters"
local uri = require "dromozoa.http.uri"

local function make_params(self, params)
  return params:param({
    oauth_callback = self.callback;
    oauth_consumer_key = self.consumer_key;
    oauth_nonce = self.nonce;
    oauth_signature_method = "HMAC-SHA1";
    oauth_timestamp = self.timestamp;
    oauth_token = self.token;
    oauth_version = "1.0";
  })
end

local class = {}

function class.new(consumer_key, token)
  return {
    consumer_key = consumer_key;
    token = token;
  }
end

function class:param(name, value)
  self.name = value
  return self
end

function class:reset(timestamp, nonce)
  if timestamp == nil then
    timestamp = os.time()
  end
  if nonce == nil then
    nonce = base64.encode_url(random_bytes(32))
  end
  self.timestamp = timestamp
  self.nonce = nonce
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
  local params = make_params(self, uri.query())
    :param(request.uri.params)
    :param(request.params)
    :sort()
  this.parameter_string = tostring(params)
  return self
end

function class:make_signature_base_string(request)
  local this = request.oauth
  this.signature_base_string = sequence_writer()
    :write(request.method:upper())
    :write("&")
    :write(uri.encode(request.uri:without_query()))
    :write("&")
    :write(uri.encode(this.parameter_string))
    :concat()
  return self
end

function class:make_signature(request, consumer_secret, token_secret)
  if token_secret == nil then
    token_secret = ""
  end
  local this = request.oauth
  local signing_key = uri.encode(consumer_secret) .. "&" .. uri.encode(token_secret)
  this.signature = base64.encode(sha1.hmac(signing_key, this.signature_base_string, "bin"))
  return self
end

function class:make_header(request)
  local this = request.oauth
  local params = make_params(self, parameters())
    :param("oauth_signature", this.signature)
    :sort(function (a, b)
      return uri.encode(a[1]) < uri.encode(b[1])
    end)
  local out = sequence_writer():write("OAuth ")
  for name, value, i in params:each() do
    if i > 1 then
      out:write(", ")
    end
    out:write(uri.encode(name), "=\"", uri.encode(value), "\"")
  end
  local authorization = out:concat()
  this.authorization = authorization
  request:header("Authorization", authorization)
  return self
end

function class:sign_header(request, consumer_secret, token_secret)
  return self
    :reset()
    :build(request)
    :make_parameter_string(request)
    :make_signature_base_string(request)
    :make_signature(request, consumer_secret, token_secret)
    :make_header(request)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, consumer_key, token)
    return setmetatable(class.new(consumer_key, token), metatable)
  end;
})
