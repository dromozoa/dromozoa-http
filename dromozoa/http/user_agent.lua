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

local class = {}

function class.new()
  return {
    options = {};
  }
end

function class:option(name, value)
  local options = self.options
  options[name] = value
  return self
end

function class:agent(agent)
  return self:option("agent", agent)
end

function class:credentials(username, password)
  return self:option("username", username):option("password", password)
end

function class:authentication(authentication)
  return self:option("authentication", authentication)
end

function class:cookie(v)
  if v == nil then
    v = true
  end
  return self:option("cookie", v)
end

function class:verbose(v)
  if v == nil then
    v = true
  end
  return self:option("verbose", v)
end

function class:request(request)
  request:build()

  local options = self.options
  local cookies = self.cookies
  local method = request.method
  local uri = request.uri
  local headers = request.headers
  local content_type = request.content_type
  local content = request.content
  local params = request.params

  local commands = sequence():push("curl")
  local tmpnames = sequence()

  commands:push("--globoff")
  commands:push("--location")

  local agent = options.agent
  if agent ~= nil then
    commands:push("--user-agent", shell.quote(agent))
  end

  local username = options.username
  local password = options.password
  if username ~= nil and password ~= nil then
    commands:push("--user", shell.quote(username .. ":" .. password))
    local authentication = options.authentication
    if authentication == "basic" then
      commands:push("--basic")
    elseif authentication == "digest" then
      commands:push("--digest")
    else
      commands:push("--anyauth")
    end
  end

  local cookie_jar
  if options.cookie then
    cookie_jar = os.tmpname()
    tmpnames:push(cookie_jar)
    if cookies ~= nil then
      assert(write_file(cookie_jar, cookies))
      commands:push("--cookie", shell.quote(cookie_jar))
    end
    commands:push("--cookie-jar", shell.quote(cookie_jar))
  end

  if options.verbose then
    commands:push("--verbose")
  else
    commands:push("--silent")
  end

  if method == "HEAD" then
    commands:push("--head")
  elseif method ~= "GET" and method ~= "POST" then
    commands:push("--request", shell.quote(method))
  end
  commands:push(shell.quote(uri))

  for header in headers:each() do
    commands:push("--header", shell.quote(header[1] .. ": " .. header[2]))
  end
  if content_type ~= nil then
    if content_type == "multipart/form-data" then
      for param in params:each() do
        local k, v = param[1], param[2]
        if type(v) == "table" then
          local tmpname = os.tmpname()
          tmpnames:push(tmpname)
          assert(write_file(tmpname, v.content))
          local out = sequence_writer():write(k, "=@\"", tmpname, "\"")
          if v.content_type ~= nil then
            out:write(";type=\"", v.content_type, "\"")
          end
          if v.filename ~= nil then
            out:write(";filename=\"", v.filename, "\"")
          end
          commands:push("--form", shell.quote(out:concat()))
        else
          commands:push("--form-string", shell.quote(k .. "=" ..v))
        end
      end
    else
      if content_type ~= "application/x-www-form-urlencoded" then
        commands:push("--header", shell.quote("Content-Type: " .. content_type))
      end
      local tmpname = os.tmpname()
      tmpnames:push(tmpname)
      assert(write_file(tmpname, content))
      commands:push("--data-binary", shell.quote("@" .. tmpname))
    end
  end

  commands:push("--write-out", [['%{http_code},%{content_type}']])

  local output = os.tmpname()
  tmpnames:push(output)
  commands:push("--output", shell.quote(output))

  local command = commands:concat(" ")
  local result, what, code = shell.eval(command)

  local content = ""
  if method ~= "HEAD" then
    content = assert(read_file(output))
  end
  if cookie_jar ~= nil then
    self.cookies = assert(read_file(cookie_jar))
  end
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
