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
local http = require "dromozoa.http"

local access_key = assert(os.getenv("dromozoa_http_access_key"))
local secret_key = assert(os.getenv("dromozoa_http_secret_key"))

local bucket = "dromozoa"
local host = bucket .. ".s3-ap-northeast-1.amazonaws.com"

local ua = http:user_agent()
ua:agent("dromozoa-http")

local aws4 = http.aws4("ap-northeast-1", "s3")

local request = http.request("GET", http.uri("http", host, "/"))
aws4:sign(request, access_key, secret_key)
local response = ua:request(request)
assert(response.code == 200)
assert(response.content_type == "application/xml")

local request = http.request("GET", http.uri("http", host, "/foo.txt"))
aws4:sign(request, access_key, secret_key)
local response = ua:request(request)
assert(response.code == 200)
assert(response.content == "foo\n")

local request = http.request("PUT", http.uri("http", host, "/qux.txt"))
request:header("Content-Type", "text/plain; charset=UTF-8")
request.content = "日本語\n"
aws4:sign(request, access_key, secret_key)
local response = ua:request(request)
assert(response.code == 200)
assert(response.content == "")
