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

local json = require "dromozoa.commons.json"
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha256 = require "dromozoa.commons.sha256"
local http = require "dromozoa.http"

local access_key = "AKIAIOSFODNN7EXAMPLE"
local secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

local request = http.request("GET", http.uri("http", "examplebucket.s3.amazonaws.com", "/test.txt"))
request:header("Range", "bytes=0-9")

local aws4 = http.aws4("us-east-1", "s3")
aws4.date = "20130524"
aws4.datetime = "20130524T000000Z"

aws4:build_request(request)

local content_sha256 = request.aws4.content_sha256
assert(content_sha256 == [[
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])

local canonical_request = aws4:build_canonical_request(request)
local signed_headers = request.aws4.signed_headers
assert(canonical_request == [[
GET
/test.txt

host:examplebucket.s3.amazonaws.com
range:bytes=0-9
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z

host;range;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])

local string_to_sign = aws4:build_string_to_sign(canonical_request)
assert(string_to_sign == [[
AWS4-HMAC-SHA256
20130524T000000Z
20130524/us-east-1/s3/aws4_request
7344ae5b7ee6c3e7e6b0fe0640412a37625d1fbfff95c48bbb2dc43964946972]])

local signature = aws4:build_signature(string_to_sign, secret_key)
assert(signature == [[
f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41]])

local authorization = aws4:build_authorization(request, signature, access_key)
assert(authorization == [[
AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;range;x-amz-content-sha256;x-amz-date,Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41]])
