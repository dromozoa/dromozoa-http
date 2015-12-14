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

local empty = require "dromozoa.commons.empty"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local uri = require "dromozoa.commons.uri"
local query = require "dromozoa.http.query"

local class = {
  query = query;
}

function class.new(scheme, authority, path)
  return {
    scheme = scheme;
    authority = authority;
    path = path;
    params = query();
  }
end

function class:param(...)
  self.params:param(...)
  return self
end

function class:without_query()
  return class(self.scheme, self.authority, self.path)
end

local metatable = {
  __index = class;
}

function metatable:__tostring()
  local params = self.params
  local out = sequence_writer()
  out:write(self.scheme, "://", self.authority, self.path)
  if not empty(params) then
    out:write("?", tostring(params))
  end
  return out:concat()
end

return setmetatable(class, {
  __index = uri;
  __call = function (_, scheme, authority, path)
    return setmetatable(class.new(scheme, authority, path), metatable)
  end;
})
