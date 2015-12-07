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
  if char == " " then
    return "+"
  else
    return ("%%%02X"):format(char:byte())
  end
end

local function encode(s)
  return (tostring(s):gsub("[^%*%-%.0-9A-Z_a-z]", encoder))
end

local class = {}

function class.new(method, uri, content_type, content)
  if method == "POST" or method == "PUT" then
    if content_type == nil then
      content_type = "application/x-www-form-urlencoded"
    end
  end
  return {
    method = method;
    uri = uri;
    headers = sequence();
    content_type = content_type;
    content = content;
  }
end

function class:header(name, value)
  local headers = self.headers
  headers:push({ name, value })
  return self
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
  local content_type = self.content_type
  local content = self.content
  local params = self.params
  if content_type == "application/x-www-form-urlencoded" and content == nil and params ~= nil then
    local out = sequence_writer()
    local first = true
    for param in params:each() do
      local k, v = param[1], param[2]
      if first then
        first = false
      else
        out:write("&")
      end
      out:write(encode(k), "=", encode(v))
    end
    content = out:concat()
    self.content = content
    self.params = nil
  end
  return content
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, method, uri, content_type, content)
    return setmetatable(class.new(method, uri, content_type, content), metatable)
  end;
})