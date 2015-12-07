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

local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha256 = require "dromozoa.commons.sha256"
local http = require "dromozoa.http"

-- local access_key = os.getenv("dromozoa_http_access_key")
-- local secret_key = os.getenv("dromozoa_http_secret_key")
--
-- if access_key == nil or secret_key == nil then
--   return
-- end

local access_key = "AKIAIOSFODNN7EXAMPLE"
local secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
local date = "20130524"
local timestamp = "20130524T000000Z"
local bucket = "examplebucket"
local host = bucket .. ".s3.amazonaws.com"
local region = "us-east-1"
local method = "GET"
local path = "/test.txt"
local query = ""
local content = ""

local out = sequence_writer()
out:write(method, "\n")
out:write(path, "\n")
out:write(query, "\n")
out:write("host:", host, "\n")
out:write("range:bytes=0-9\n")
out:write("x-amz-content-sha256:", sha256.hex(content), "\n")
out:write("x-amz-date:", timestamp, "\n")
out:write("\n")
out:write("host;range;x-amz-content-sha256;x-amz-date", "\n")
out:write(sha256.hex(content))
local canonical_request = out:concat()

local out = sequence_writer()
out:write("AWS4-HMAC-SHA256", "\n")
out:write(timestamp, "\n")
out:write(date, "/", region, "/s3/aws4_request", "\n")
out:write(sha256.hex(canonical_request))
local string_to_sign = out:concat()

print(string_to_sign)
print(sha256.hex(canonical_request))

local hash1 = sha256.hmac("AWS4" .. secret_key, date, "bin")
local hash2 = sha256.hmac(hash1, region, "bin")
local hash3 = sha256.hmac(hash2, "s3", "bin")
local hash4 = sha256.hmac(hash3, "aws4_request", "bin")
local signature = sha256.hmac(hash4, string_to_sign, "hex")

print(signature)

-- AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;range;x-amz-content-sha256;x-amz-date,
-- Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41

