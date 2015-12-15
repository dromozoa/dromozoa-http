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

local ipairs = require "dromozoa.commons.ipairs"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local pairs = require "dromozoa.commons.pairs"
local sequence = require "dromozoa.commons.sequence"

local class = {}

function class:param(that, value)
  if type(that) == "table" then
    for name, value in pairs(that) do
      self:push({ name, value })
    end
  else
    self:push({ that, value })
  end
  return self
end

function class:each()
  return coroutine.wrap(function ()
    for i, param in ipairs(self) do
      coroutine.yield(param[1], param[2], i)
    end
  end)
end

function class:to_map(that)
  if that == nil then
    that = linked_hash_table()
  end
  for name, value in self:each() do
    that[name] = value
  end
  return that
end

local metatable = {
  __index = class;
  __pairs = class.each;
}

return setmetatable(class, {
  __index = sequence;
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
