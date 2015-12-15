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

local content = http.request("POST", http.uri("http", "localhost", "/"))
  :param({
    foo = " &=";
    bar = "日本語";
  })
  :build()
content = content .. "&baz&=qux"

local form = http.form.decode(content):to_map()
assert(form.foo == " &=")
assert(form.bar == "日本語")
assert(form.baz == "")
assert(form[""] == "qux")
