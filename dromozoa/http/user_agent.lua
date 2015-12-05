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
local read_file = require "dromozoa.commons.read_file"
local sequence = require "dromozoa.commons.sequence"
local shell = require "dromozoa.commons.shell"

local class = {}

function class.new()
  return {
    options = {};
  }
end

function class:agent(agent)
  self.options.agent = agent
  return self
end

function class:request(req)
  local args = sequence()

  args:push("--verbose")
  -- args:push("--silent")
  args:push("--location")

  local agent = self.options.agent
  if agent ~= nil then
    args:push("--user-agent", shell.quote(agent))
  end

  for _, header in ipairs(req.headers) do
    args:push("--header", shell.quote(header[1] .. ": " .. header[2]))
  end

  args:push("--request", req.method, req.uri)

  args:push([[--write-out '%{http_code}']])

  local output = os.tmpname()
  args:push("--output", shell.quote(output))

  local dump_header = os.tmpname()
  args:push("--dump-header", shell.quote(dump_header))

  local command = "curl " .. args:concat(" ")
  -- print(command)

  local result, what, code = shell.eval(command)
  -- print(result, what, code)

  local content = assert(read_file(output))
  os.remove(output)

  local headers = assert(read_file(dump_header))
  os.remove(dump_header)

  -- print(headers)

  if result == nil then
    return nil, what, code
  else
    local res = class.super.response(tonumber(result))
    res.content = content
    return res
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
