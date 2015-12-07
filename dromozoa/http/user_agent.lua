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

local read_file = require "dromozoa.commons.read_file"
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local shell = require "dromozoa.commons.shell"
local write_file = require "dromozoa.commons.write_file"

local form = require "dromozoa.http.form"

local class = {}

function class.new()
  return {
    options = {};
  }
end

function class:option(name, value)
  options[name] = value
  return self
end

function class:agent(agent)
  return option("agent", agent)
end

function class:request(request)
  local options = self.options
  local method = request.method
  local uri = request.uri
  local headers = request.headers
  local content_type = request.content_type
  local content = request.content

  local commands = sequence():push("curl")
  local tmpnames = sequence()

  commands:push("--silent")
  -- commands:push("--verbose")
  commands:push("--globoff")

  if options.agent ~= nil then
    commands:push("--user-agent", shell.quote(options.agent))
  end

  if method == "HEAD" then
    commands:push("--head")
  else
    commands:push("--request", shell.quote(method))
  end
  commands:push(shell.quote(uri))

  for header in headers:each() do
    commands:push("--header", shell.quote(header[1] .. ": " .. header[2]))
  end
  if content_type ~= nil then
    if type(content) == "table" then
      if content_type == "multipart/form-data" then
        for parameter in content:each() do
          local k, v = parameter[1], parameter[2]
          local tmpname = os.tmpname()
          tmpnames:push(tmpname)
          local out = sequence_writer():write(k, "=@\"", tmpname, "\"")
          if type(v) == "table" then
            assert(write_file(tmpname, v.content))
            if v.content_type ~= nil then
              out:write(";type=\"", v.content_type, "\"")
            end
            if v.filename ~= nil then
              out:write(";filename=\"", v.filename, "\"")
            end
          else
            assert(write_file(tmpname, v))
          end
          commands:push("--form", shell.quote(out:concat()))
        end
      else
        local tmpname = os.tmpname()
        tmpnames:push(tmpname)
        local out = assert(io.open(tmpname, "wb"))
        local first = true
        for parameter in content:each() do
          local k, v = parameter[1], parameter[2]
          if first then
            first = false
          else
            out:write("&")
          end
          out:write(form.encode(k), "=", form.encode(v))
        end
        out:close()
        commands:push("--data-binary", shell.quote("@" .. tmpname))
      end
    else
      commands:push("--header", shell.quote("Content-Type: " .. content_type))
      local tmpname = os.tmpname()
      tmpnames:push(tmpname)
      assert(write_file(tmpname, content))
      commands:push("--data-binary", shell.quote("@" .. tmpname))
    end
  end

  commands:push("--write-out", [['%{http_code},%{content_type}']])

  -- commands:push("--trace-ascii", "/tmp/trace.txt")

  local tmpname = os.tmpname()
  tmpnames:push(tmpname)
  commands:push("--output", shell.quote(tmpname))

  local command = commands:concat(" ")
  print(command)
  local result, what, code = shell.eval(command)

  local content = assert(read_file(tmpname))
  for tmpname in tmpnames:each() do
    os.remove(tmpname)
  end

  if result == nil then
    return nil, what, code
  else
    local code, content_type  = result:match("^(%d+),(.*)")
    return class.super.response(tonumber(code), content_type, content)
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
