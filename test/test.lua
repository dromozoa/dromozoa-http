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

local cgi_host = "localhost"
local cgi_path = "/cgi-bin/dromozoa-http-test.cgi"
local cgi_uri = "http://" .. cgi_host .. cgi_path

local ua = http.user_agent()
ua:agent("dromozoa-http")

local request = http.request("GET", cgi_uri)
local result = assert(json.decode(assert(ua:request(request)).content))
assert(result.request_method == "GET")
assert(result.request_uri == cgi_path)
assert(result.env.HTTP_HOST == cgi_host)
assert(result.env.HTTP_USER_AGENT == "dromozoa-http")

local query = http:query():param("foo", 17):param("bar", 23):param("bar", 37):param("baz", "日本語"):build()
local request = http.request("GET", cgi_uri .. "?" .. query)
local result = assert(json.decode(assert(ua:request(request)).content))
assert(equal(result.params, {
  foo = { "17" };
  bar = { "23", "37" };
  baz = { "日本語" };
}))

local request = http.request("POST", cgi_uri)
request:param("foo", 17)
request:param("bar", 23)
request:param("bar", 37)
request:param("baz", "日本語")
local result = assert(json.decode(assert(ua:request(request)).content))
assert(result.content_type == "application/x-www-form-urlencoded")
assert(equal(result.params, {
  foo = { "17" };
  bar = { "23", "37" };
  baz = { "日本語" };
}))

local request = http.request("POST", cgi_uri .. "/301/" .. cgi_uri)
request:param("foo", 17)
request:param("bar", 23)
request:param("bar", 37)
local result = assert(json.decode(assert(ua:request(request)).content))
assert(result.request_method == "GET")
assert(result.params == nil)

local request = http.request("POST", cgi_uri .. "/308/" .. cgi_uri)
request:param("foo", 17)
request:param("bar", 23)
request:param("bar", 37)
local result = assert(json.decode(assert(ua:request(request)).content))
assert(result.request_method == "POST")
assert(equal(result.params, {
  foo = { "17" };
  bar = { "23", "37" };
}))

local request = http.request("POST", cgi_uri, "multipart/form-data")
request:param("foo", 17)
request:param("bar", 23)
request:param("bar", 37)
request:param("baz", {
  content = "日本語\n";
  content_type = "text/plain; charset=UTF-8";
  filename = "test.txt";
})
local result = assert(json.decode(assert(ua:request(request)).content))
assert(result.content_type:find("multipart/form-data", 1, true) == 1)
assert(equal(result.params.foo, { "17" }))
assert(equal(result.params.bar, { "23", "37" }))
assert(#result.params.baz, 1)
assert(result.params.baz[1].content == "日本語\n")
assert(result.params.baz[1].content_type:find("text/plain", 1, true))
assert(result.params.baz[1].content_type:find("charset=UTF-8", 1, true))
assert(result.params.baz[1].content_disposition:find("test.txt", 1, true))

local request = http.request("PUT", cgi_uri, "application/json")
request.content = json.encode({ 17, 23, 37, 42 })
local result = assert(json.decode(assert(ua:request(request)).content))
assert(result.request_method == "PUT")
assert(result.content_type == "application/json")
assert(equal(json.decode(result.content), { 17, 23, 37, 42 }))

local request = http.request("HEAD", cgi_uri)
local response = assert(ua:request(request))
assert(response.code == 200)
assert(response.content == "")
assert(response.content_type == "application/json; charset=UTF-8")

local request = http.request("GET", http.uri("http", "localhost", cgi_path):param("test", "日本語"))
local result = assert(json.decode(assert(ua:request(request)).content))
assert(equal(result.params, { test = { "日本語" } }))
