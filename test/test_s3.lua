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
local http = require "dromozoa.http"

local access_key = "AKIAIOSFODNN7EXAMPLE"
local secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
local timestamp = "20130524T000000Z"
local date = timestamp:match("^(%d+)T")
local region = "us-east-1"
local service = "s3"
local scope = date .. "/" .. region .. "/" .. service.. "/aws4_request"

local request = http.request("GET", http.uri("http", "examplebucket.s3.amazonaws.com", "/test.txt"))
request:header("Range", "bytes=0-9")
request:build()

local content = request.content
local content_sha256
if content == nil then
  content_sha256 = sha256.hex("")
else
  content_sha256 = sha256.hex(content)
end
request:header("x-amz-content-sha256", content_sha256)
request:header("x-amz-date", timestamp)

local function trim(s)
  return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

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
out:write("host:", request.uri.authority, "\n")
headers:push("host")
for header in request.headers:each() do
  local k, v = header[1]:lower(), trim(header[2])
  out:write(k, ":", v, "\n")
  headers:push(k)
end
out:write("\n")
local signed_headers = headers:concat(";")
out:write(signed_headers, "\n")
out:write(content_sha256)
local canonical_request = out:concat()

assert(canonical_request == [[
GET
/test.txt

host:examplebucket.s3.amazonaws.com
range:bytes=0-9
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z

host;range;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])

local out = sequence_writer()
out:write("AWS4-HMAC-SHA256", "\n")
out:write(timestamp, "\n")
out:write(scope, "\n")
out:write(sha256.hex(canonical_request))
local string_to_sign = out:concat()

assert(string_to_sign == [[
AWS4-HMAC-SHA256
20130524T000000Z
20130524/us-east-1/s3/aws4_request
7344ae5b7ee6c3e7e6b0fe0640412a37625d1fbfff95c48bbb2dc43964946972]])

local h1 = sha256.hmac("AWS4" .. secret_key, date, "bin")
local h2 = sha256.hmac(h1, region, "bin")
local h3 = sha256.hmac(h2, service, "bin")
local h4 = sha256.hmac(h3, "aws4_request", "bin")
local signature = sha256.hmac(h4, string_to_sign, "hex")

assert(signature == [[
f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41]])

local out = sequence_writer()
out:write("AWS4-HMAC-SHA256")
out:write(" Credential=", access_key, "/", scope)
out:write(",SignedHeaders=", signed_headers)
out:write(",Signature=", signature)
local authorization = out:concat()

assert(authorization == [[
AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;range;x-amz-content-sha256;x-amz-date,Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41]])

request:header("Authorization", authorization)
