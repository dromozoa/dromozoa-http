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
local uri = require "dromozoa.commons.uri"
local parameters = require "dromozoa.http.parameters"

local function encode(name, value)
  return uri.encode(name) .. "=" .. uri.encode(value)
end

local function compare(a, b)
  return encode(a[1], a[2]) < encode(b[1], b[2])
end

local class = {}

function class:sort()
  parameters.sort(self, compare)
  return self
end

local metatable = {
  __index = class;
  __pairs = parameters.each;
}

function metatable:__tostring()
  local out = sequence_writer()
  for name, value, i in self:each() do
    if i > 1 then
      out:write("&")
    end
    out:write(encode(name, value))
  end
  return out:concat()
end

return setmetatable(class, {
  __index = parameters;
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
