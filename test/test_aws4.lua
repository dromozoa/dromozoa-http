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

local access_key_id = "AKIAIOSFODNN7EXAMPLE"
local secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
local aws4 = http.aws4("us-east-1", "s3"):reset("20130524T000000Z")

local request = http.request("GET", http.uri("http", "examplebucket.s3.amazonaws.com", "/test.txt"))
request:header("Range", "bytes=0-9")

aws4:build(request)
assert(request.aws4.content_sha256== [[
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])

aws4:make_canonical_request(request)
assert(request.aws4.canonical_request == [[
GET
/test.txt

host:examplebucket.s3.amazonaws.com
range:bytes=0-9
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z

host;range;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])

aws4:make_string_to_sign(request)
assert(request.aws4.string_to_sign == [[
AWS4-HMAC-SHA256
20130524T000000Z
20130524/us-east-1/s3/aws4_request
7344ae5b7ee6c3e7e6b0fe0640412a37625d1fbfff95c48bbb2dc43964946972]])

aws4:make_signature(request, secret_access_key)
assert(request.aws4.signature == [[
f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41]])

aws4:make_header(request, access_key_id)
assert(request.aws4.authorization == [[
AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;range;x-amz-content-sha256;x-amz-date,Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41]])

local request = http.request("GET", http.uri("http", "examplebucket.s3.amazonaws.com", "/test.txt"))
request:header("Range", "bytes=0-9")
aws4
  :build(request)
  :make_canonical_request(request)
  :make_string_to_sign(request)
  :make_signature(request, secret_access_key)
  :make_header(request, access_key_id)
assert(request.aws4.authorization == [[
AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;range;x-amz-content-sha256;x-amz-date,Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41]])

local request = http.request("GET", http.uri("http", "examplebucket.s3.amazonaws.com", "/test.txt"))
aws4:build(request)
request:header("Range", "bytes=0-9")
aws4:make_canonical_request(request)
assert(request.aws4.canonical_request == [[
GET
/test.txt

host:examplebucket.s3.amazonaws.com
range:bytes=0-9
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z

host;range;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])

local request = http.request("GET", http.uri("http", "examplebucket.s3.amazonaws.com", "/"):param("max-keys", 2):param("prefix", "J"))
aws4
  :build(request)
  :make_canonical_request(request)
  :make_string_to_sign(request)
  :make_signature(request, secret_access_key)
  :make_header(request, access_key_id)
assert(request.aws4.canonical_request == [[
GET
/
max-keys=2&prefix=J
host:examplebucket.s3.amazonaws.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])
assert(request.aws4.authorization == [[
AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=34b48302e7b5fa45bde8084f4b7868a86f0a534bc59db6670ed5711ef69dc6f7]])

local request = http.request("GET", http.uri("http", "examplebucket.s3.amazonaws.com", "/"):param("prefix", "J"):param("max-keys", 2))
aws4
  :build(request)
  :make_canonical_request(request)
  :make_string_to_sign(request)
  :make_signature(request, secret_access_key)
  :make_header(request, access_key_id)
assert(request.aws4.canonical_request == [[
GET
/
max-keys=2&prefix=J
host:examplebucket.s3.amazonaws.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])
assert(request.aws4.authorization == [[
AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=34b48302e7b5fa45bde8084f4b7868a86f0a534bc59db6670ed5711ef69dc6f7]])

local uri = http.uri("http", "host.foo.com", "/")
    :param("x", "d")
    :param("x", "b")
    :param("x", "c")
    :param("x", "a")
local request = http.request("GET", uri)
    :header("x-test", "d")
    :header("x-test", "b")
    :header("X-Test", "c")
    :header("X-Test", "a")
aws4
  :build(request)
  :make_canonical_request(request)
-- print(request.aws4.canonical_request)
assert(request.aws4.canonical_request == [[
GET
/
x=a&x=b&x=c&x=d
host:host.foo.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20130524T000000Z
x-test:a,b,c,d

host;x-amz-content-sha256;x-amz-date;x-test
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]])
