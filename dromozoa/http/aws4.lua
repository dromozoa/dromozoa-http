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

local function compare(a, b)
  return a[1] < b[1]
end

local class = {}

function class.new(region, service)
  return class.reset({
    region = region;
    service = service;
  })
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
  local content = request.content
  local content_sha256
  if content == nil then
    content_sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  else
    content_sha256 = sha256.hex(content)
  end
  this.content_sha256 = content_sha256
  request:header("x-amz-content-sha256", content_sha256)
  request:header("x-amz-date", self.datetime)
  return self
end

function class:make_canonical_request(request)
  local this = request.aws4
  local out = sequence_writer()
  out:write(request.method, "\n")
  out:write(request.uri.path, "\n")

  local query = request.uri.query
  if query == nil then
    out:write("\n")
  else
    query = clone(query)
    query.params:sort(compare)
    out:write(tostring(query), "\n")
  end

  local headers = sequence()
  headers:push({ "host", trim(request.uri.authority) })
  local content_type = request.content_type
  if content_type ~= nil then
    headers:push({ "content-type", trim(content_type) })
  end
  for header in request.headers:each() do
    headers:push({ header[1]:lower(), trim(header[2]) })
  end
  headers:sort(compare)

  local names = sequence()
  for header in headers:each() do
    names:push(header[1])
    out:write(header[1], ":", header[2], "\n")
  end
  out:write("\n")

  local signed_headers = names:concat(";")
  this.signed_headers = signed_headers
  out:write(signed_headers, "\n")
  out:write(this.content_sha256)
  this.canonical_request = out:concat()
  return self
end

function class:make_string_to_sign(request)
  local this = request.aws4
  local out = sequence_writer()
  out:write("AWS4-HMAC-SHA256", "\n")
  out:write(self.datetime, "\n")
  out:write(self.scope, "\n")
  out:write(sha256.hex(this.canonical_request))
  this.string_to_sign = out:concat()
  return self
end

function class:make_signature(request, secret_key)
  local this = request.aws4
  local h1 = sha256.hmac("AWS4" .. secret_key, self.date, "bin")
  local h2 = sha256.hmac(h1, self.region, "bin")
  local h3 = sha256.hmac(h2, self.service, "bin")
  local h4 = sha256.hmac(h3, "aws4_request", "bin")
  this.signature = sha256.hmac(h4, this.string_to_sign, "hex")
  return self
end

function class:make_header(request, access_key)
  local this = request.aws4
  local out = sequence_writer()
  out:write("AWS4-HMAC-SHA256 ")
  out:write("Credential=", access_key, "/", self.scope, ",")
  out:write("SignedHeaders=", this.signed_headers, ",")
  out:write("Signature=", this.signature)
  local authorization = out:concat()
  this.authorization = authorization
  request:header("Authorization", authorization)
  return self
end

function class:sign_header(request, access_key, secret_key)
  return self
      :build(request)
      :make_canonical_request(request)
      :make_string_to_sign(request)
      :make_signature(request, secret_key)
      :make_header(request, access_key)
end

function class:sign_query(request, access_key, secret_key)
  return self
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, region, service)
    return setmetatable(class.new(region, service), metatable)
  end;
})
