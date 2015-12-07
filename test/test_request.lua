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

local request = http.request("POST", "http://localhost/")
assert(request.content_type == "application/x-www-form-urlencoded")
request:param("foo", 17)
request:param("bar", 23)
request:param("bar", 37)
assert(request.content == nil)
assert(request.params ~= nil)
request:build()
assert(request.content == "foo=17&bar=23&bar=37")
assert(request.params == nil)
request:build()
assert(request.content == "foo=17&bar=23&bar=37")
assert(request.params == nil)

local request = http.request("POST", "http://localhost/")
request:param("foo", " ")
request:param("bar", "&=")
request:param("baz", "09AZaz")
request:param("qux", "日本語")
assert(request:build() == "foo=+&bar=%26%3D&baz=09AZaz&qux=%E6%97%A5%E6%9C%AC%E8%AA%9E")
