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

local form = require "dromozoa.http.form"
local parameters = require "dromozoa.http.parameters"

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
    headers = parameters();
    content_type = content_type;
    content = content;
    params = parameters();
  }
end

function class:option(name, value)
  self.options[name] = value
  return self
end

function class:save(filename)
  return self:option("save", filename)
end

function class:header(...)
  self.headers:param(...)
  return self
end

function class:param(...)
  self.params:param(...)
  return self
end

function class:build()
  local content = self.content
  if self.content_type ~= "multipart/form-data" and content == nil then
    content = form.encode(self.params)
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
