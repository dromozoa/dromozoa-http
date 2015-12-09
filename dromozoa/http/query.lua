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

local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"

local function encoder(char)
  return ("%%%02X"):format(char:byte())
end

local function encode(s)
  return (tostring(s):gsub("[^A-Za-z0-9%-%.%_%~]", encoder))
end

local class = {}

function class.new()
  return {}
end

function class:param(name, value)
  local params = self.params
  if params == nil then
    params = sequence()
    self.params = params
  end
  params:push({ name, value })
  return self
end

function class:build()
  local params = self.params
  if params == nil then
    return nil
  else
    local out = sequence_writer()
    local first = true
    for param in params:each() do
      local name, value = param[1], param[2]
      if first then
        first = false
      else
        out:write("&")
      end
      out:write(encode(name), "=", encode(value))
    end
    return out:concat()
  end
end

local metatable = {
  __index = class;
  __tostring = class.build;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
