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

local clone = require "dromozoa.commons.clone"
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha256 = require "dromozoa.commons.sha256"

local function trim(s)
  return (tostring(s):gsub("^[ \t]+", ""):gsub("[ \t]+$", ""))
end

local class = {}

function class.new(region, service, access_key_id, security_token)
  return {
    region = region;
    service = service;
    access_key_id = access_key_id;
    security_token = security_token;
  }
end

function class:reset(datetime)
  if datetime == nil then
    datetime = os.date("!%Y%m%dT%H%M%SZ")
  end
  local date = assert(datetime:match("^(%d+)T"))
  self.date = date
  self.datetime = datetime
  self.scope = date .. "/" .. self.region .. "/" .. self.service .. "/aws4_request"
  return self
end

function class:build(request)
  request:build()
  local this = request.aws4
  if this == nil then
    this = {}
    request.aws4 = this
  end
  local content_sha256 = sha256.hex(request.content)
  this.content_sha256 = content_sha256
  request
    :header("x-amz-content-sha256", content_sha256)
    :header("x-amz-date", self.datetime)
  local security_token = self.security_token
  if security_token ~= nil then
    request:header("x-amz-security-token", security_token)
  end
  return self
end

function class:make_canonical_request(request)
  local this = request.aws4
  local out = sequence_writer()
    :write(request.method, "\n")
    :write(request.uri.path, "\n")
    :write(tostring(clone(request.uri.params):sort()), "\n")

  local canonical_header_map = {}
  local canonical_headers = sequence()

  local canonical_header = { "host", sequence():push(trim(request.uri.authority)) }
  canonical_header_map.host = canonical_header
  canonical_headers:push(canonical_header)

  local content_type = request.content_type
  if content_type ~= nil then
    local canonical_header = { "content-type", sequence():push(trim(content_type)) }
    canonical_header_map["content-type"] = canonical_header
    canonical_headers:push(canonical_header)
  end

  for name, value in request.headers:each() do
    local name, value = name:lower(), trim(value)
    local canonical_header = canonical_header_map[name]
    if canonical_header == nil then
      canonical_header = { name, sequence():push(value) }
      canonical_header_map[name] = canonical_header
      canonical_headers:push(canonical_header)
    else
      canonical_header[2]:push(value)
    end
  end

  canonical_headers:sort(function(a, b)
    return a[1] < b[1]
  end)

  local canonical_header_names = sequence()
  for canonical_header in canonical_headers:each() do
    local name, value = canonical_header[1], canonical_header[2]:sort():concat(",")
    canonical_header_names:push(name)
    out:write(name, ":", value, "\n")
  end
  out:write("\n")

  local signed_headers = canonical_header_names:concat(";")
  this.signed_headers = signed_headers
  this.canonical_request = out
    :write(signed_headers, "\n")
    :write(this.content_sha256)
    :concat()
  return self
end

function class:make_string_to_sign(request)
  local this = request.aws4
  this.string_to_sign = sequence_writer()
    :write("AWS4-HMAC-SHA256", "\n")
    :write(self.datetime, "\n")
    :write(self.scope, "\n")
    :write(sha256.hex(this.canonical_request))
    :concat()
  return self
end

function class:make_signature(request, secret_access_key)
  local this = request.aws4
  local h1 = sha256.hmac("AWS4" .. secret_access_key, self.date, "bin")
  local h2 = sha256.hmac(h1, self.region, "bin")
  local h3 = sha256.hmac(h2, self.service, "bin")
  local h4 = sha256.hmac(h3, "aws4_request", "bin")
  this.signature = sha256.hmac(h4, this.string_to_sign, "hex")
  return self
end

function class:make_header(request)
  local this = request.aws4
  local authorization = sequence_writer()
    :write("AWS4-HMAC-SHA256 ")
    :write("Credential=", self.access_key_id, "/", self.scope, ",")
    :write("SignedHeaders=", this.signed_headers, ",")
    :write("Signature=", this.signature)
    :concat()
  this.authorization = authorization
  request:header("Authorization", authorization)
  return self
end

function class:sign_header(request, secret_access_key)
  return self
    :reset()
    :build(request)
    :make_canonical_request(request)
    :make_string_to_sign(request)
    :make_signature(request, secret_access_key)
    :make_header(request, self.access_key_id)
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, region, service, access_key_id, security_token)
    return setmetatable(class.new(region, service, access_key_id, security_token), metatable)
  end;
})
