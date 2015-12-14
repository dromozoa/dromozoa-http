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

local pairs = require "dromozoa.commons.pairs"
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local uri = require "dromozoa.commons.uri"

local class = {}

function class.new(method, uri, content_type, content)
  if method == "POST" or method == "PUT" then
    if content_type == nil then
      content_type = "application/x-www-form-urlencoded"
    end
  end
  return {
    options = {};
    method = method;
    uri = uri;
    headers = sequence();
    content_type = content_type;
    content = content;
  }
end

function class:option(name, value)
  self.options[name] = value
  return self
end

function class:save(filename)
  return self:option("save", filename)
end

function class:header(that, value)
  if type(that) == "table" then
    for name, value in pairs(that) do
      self.headers:push({ name, value })
    end
  else
    self.headers:push({ that, value })
  end
  return self
end

function class:param(that, value)
  local params = self.params
  if params == nil then
    params = sequence()
    self.params = params
  end
  if type(that) == "table" then
    for name, value in pairs(that) do
      params:push({ name, value })
    end
  else
    params:push({ that, value })
  end
  return self
end

function class:build()
  local content = self.content
  local params = self.params
  if self.content_type ~= "multipart/form-data" and content == nil then
    if params == nil then
      content = ""
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
        out:write(uri.encode_html5(name), "=", uri.encode_html5(value))
      end
      content = out:concat()
    end
    self.content = content
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
