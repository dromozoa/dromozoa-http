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
  return uri.encode_html5(name) .. "=" .. uri.encode_html5(value)
end

local class = {}

function class.encode(params)
  local out = sequence_writer()
  for name, value, i in params:each() do
    if i > 1 then
      out:write("&")
    end
    out:write(encode(name, value))
  end
  return out:concat()
end

function class.decode(s)
  local result = parameters()
  for param in s:gmatch("[^%&]+") do
    local name, value = param:match("^([^%=]*)%=(.*)")
    if name == nil then
      result:param(uri.decode(param), "")
    else
      result:param(uri.decode(name), uri.decode(value))
    end
  end
  return result
end

return class
