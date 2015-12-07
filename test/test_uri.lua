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

local query = http.query()
query:param("foo", 17)
query:param("bar", 23)
query:param("bar", 37)
query:param("baz", "日本語")
assert(tostring(query) == "foo=17&bar=23&bar=37&baz=%E6%97%A5%E6%9C%AC%E8%AA%9E")
assert(tostring(http.query():param("foo", "'()")) == "foo=%27%28%29")
assert("?" .. http.query():param("foo", "bar"):build() == "?foo=bar")

local uri = http.uri("http", "localhost", "/cgi-bin/dromozoa-http-test.cgi")
assert(tostring(uri) == "http://localhost/cgi-bin/dromozoa-http-test.cgi")

local uri = http.uri("http", "localhost", "/cgi-bin/dromozoa-http-test.cgi")
uri.query = http.query():param("foo", 17):param("bar", 23)
assert(tostring(uri) == "http://localhost/cgi-bin/dromozoa-http-test.cgi?foo=17&bar=23")

local uri = http.uri("http", "localhost", "/cgi-bin/dromozoa-http-test.cgi"):param("foo", 17):param("bar", 23)
assert(tostring(uri) == "http://localhost/cgi-bin/dromozoa-http-test.cgi?foo=17&bar=23")
