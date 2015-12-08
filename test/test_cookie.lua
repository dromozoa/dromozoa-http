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

local equal = require "dromozoa.commons.equal"
local json = require "dromozoa.commons.json"
local http = require "dromozoa.http"

local ua = http.user_agent():cookie()

local request = http.request("GET", http.uri("http", "localhost", "/cgi-bin/dromozoa-http-test.cgi/set-cookie/foo/42"))
local result = assert(json.decode(assert(ua:request(request)).content))
assert(result.cookies == nil)

local request = http.request("GET", http.uri("http", "localhost", "/cgi-bin/dromozoa-http-test.cgi/set-cookie/foo/69"))
local result = assert(json.decode(assert(ua:request(request)).content))
assert(equal(result.cookies, { foo = "42" }))

local request = http.request("GET", http.uri("http", "localhost", "/cgi-bin/dromozoa-http-test.cgi"))
local result = assert(json.decode(assert(ua:request(request)).content))
assert(equal(result.cookies, { foo = "69" }))
