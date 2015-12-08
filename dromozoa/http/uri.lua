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

local class = {}

function class.new(scheme, authority, path, query)
  return {
    scheme = scheme;
    authority = authority;
    path = path;
    query = query;
  }
end

function class:param(name, value)
  local query = self.query
  if query == nil then
    query = self.super.query()
    self.query = query
  end
  query:param(name, value)
  return self
end

function class:build()
  local out = sequence_writer()
  out:write(self.scheme, "://", self.authority, self.path)
  local query = self.query
  if query ~= nil then
    out:write("?", tostring(query))
  end
  return out:concat()
end

local metatable = {
  __index = class;
  __tostring = class.build;
}

return setmetatable(class, {
  __call = function (_, scheme, authority, path, query)
    return setmetatable(class.new(scheme, authority, path, query), metatable)
  end;
})
