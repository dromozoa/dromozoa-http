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

-- local ua = http.user_agent()
-- ua:cookie_jar(os.tmpname())
-- ua.agent = "dromozoa-http"

-- local cookie_jar = os.tmpname()

local ua = http.user_agent()
-- ua:agent("dromozoa-http")

-- print(json.encode(ua))

-- local req = http.request("PUT", "http://localhost/", "application/json; charset=UTF-8", "[17,23,37,42]")
local req = http.request("POST", "http://localhost/", "multipart/form-data")
-- local req = http.request("GET", "http://localhost/")
-- req:header("X-Int", 42)
-- req:header("X-String", "foo")

req:parameter("foo", "bar")
   :parameter("bar", { content_type = "text/plain; charset=UTF-8", filename = "bar.txt", content = "baz\n" })

print(json.encode(req))

local res = ua:request(req)
if res then
  print(json.encode(res))
end

-- os.remove(cookie_jar)

--[[
local res = ua:request(req)
if res:is_success() then
  print(res:cotnent())
else
  print(res:status_line())
end

local req = http.request("PUT", "", {})
req:content_type("application/json; charset=UTF-8")
req:content("{}")

local req = http.request("POST", uri)
req:form({
  foo = 17;
  bar = 23;
  baz = 42;
})
]]
