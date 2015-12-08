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

local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha256 = require "dromozoa.commons.sha256"

local function trim(s)
  return (tostring(s):gsub("^[ \t]+", ""):gsub("[ \t]+$", ""))
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

function class:build_request(request, time)
  request:build()
  local aws4 = request.aws4
  if aws4 == nil then
    aws4 = {}
    request.aws4 = aws4
  end
  local content = request.content
  local content_sha256
  if content == nil then
    content_sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  else
    content_sha256 = sha256.hex(content)
  end
  aws4.content_sha256 = content_sha256
  request:header("x-amz-content-sha256", content_sha256)
  request:header("x-amz-date", self.datetime)
end

function class:build_canonical_request(request)
  local aws4 = request.aws4
  local out = sequence_writer()
  out:write(request.method, "\n")
  out:write(request.uri.path, "\n")
  local query = request.uri.query
  if query == nil then
    out:write("\n")
  else
    out:write(tostring(query), "\n")
  end
  local headers = sequence()
  headers:push("host")
  out:write("host:", request.uri.authority, "\n")
  for header in request.headers:each() do
    local k, v = header[1]:lower(), trim(header[2])
    headers:push(k)
    out:write(k, ":", v, "\n")
  end
  out:write("\n")
  local signed_headers = headers:concat(";")
  aws4.signed_headers = signed_headers
  out:write(signed_headers, "\n")
  out:write(aws4.content_sha256)
  return out:concat()
end

function class:build_string_to_sign(canonical_request)
  local out = sequence_writer()
  out:write("AWS4-HMAC-SHA256", "\n")
  out:write(self.datetime, "\n")
  out:write(self.scope, "\n")
  out:write(sha256.hex(canonical_request))
  return out:concat()
end

function class:build_signature(string_to_sign, secret_key)
  local h1 = sha256.hmac("AWS4" .. secret_key, self.date, "bin")
  local h2 = sha256.hmac(h1, self.region, "bin")
  local h3 = sha256.hmac(h2, self.service, "bin")
  local h4 = sha256.hmac(h3, "aws4_request", "bin")
  return sha256.hmac(h4, string_to_sign, "hex")
end

function class:build_authorization(request, signature, access_key)
  local aws4 = request.aws4
  local out = sequence_writer()
  out:write("AWS4-HMAC-SHA256")
  out:write(" Credential=", access_key, "/", self.scope)
  out:write(",SignedHeaders=", aws4.signed_headers)
  out:write(",Signature=", signature)
  return out:concat()
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, region, service)
    return setmetatable(class.new(region, service), metatable)
  end;
})
