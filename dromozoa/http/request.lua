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
  self.headers:push({ name, value })
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

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, method, uri, content_type, content)
    return setmetatable(class.new(method, uri, content_type, content), metatable)
  end;
})
