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
local response = require "dromozoa.http.response"

local class = {}

function class.new(agent)
  return {
    options = {
      agent = agent;
    };
  }
end

function class:option(name, value)
  self.options[name] = value
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

function class:cookie(enabled)
  if enabled == nil then
    enabled = true
  end
  return self:option("cookie", enabled)
end

function class:fail(enabled)
  if enabled == nil then
    enabled = true
  end
  return self:option("fail", enabled)
end

function class:verbose(enabled)
  if enabled == nil then
    enabled = true
  end
  return self:option("verbose", enabled)
end

function class:request(request)
  request:build()

  local options = self.options
  local agent = options.agent
  local cookies = self.cookies
  local username = options.username
  local password = options.password
  local fail = options.fail
  local verbose = options.verbose

  local request_options = request.options
  local save = request_options.save
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
  commands:push("--trace-time")

  if agent ~= nil then
    commands:push("--user-agent", shell.quote(agent))
  end

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

  if fail then
    commands:push("--fail")
  end

  if verbose then
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

  for name, value in headers:each() do
    commands:push("--header", shell.quote(name .. ": " .. value))
  end

  if content_type ~= nil then
    if content_type == "multipart/form-data" then
      for name, value in params:each() do
        if type(value) == "table" then
          local tmpname = os.tmpname()
          tmpnames:push(tmpname)
          assert(write_file(tmpname, value.content))
          local out = sequence_writer():write(name, "=@\"", tmpname, "\"")
          if value.content_type ~= nil then
            out:write(";type=\"", value.content_type, "\"")
          end
          if value.filename ~= nil then
            out:write(";filename=\"", value.filename, "\"")
          end
          commands:push("--form", shell.quote(out:concat()))
        else
          commands:push("--form-string", shell.quote(name .. "=" ..value))
        end
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

  local output
  local content
  if method == "HEAD" then
    content = ""
    commands:push("--output", "/dev/null")
  elseif save then
    commands:push("--output", shell.quote(save))
  else
    output = os.tmpname()
    tmpnames:push(output)
    commands:push("--output", shell.quote(output))
  end

  local command = commands:concat(" ")
  if verbose then
    io.stderr:write(command, "\n")
    io.stderr:flush()
  end
  local result, what, code = shell.eval(command)

  if output ~= nil then
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
    local code, content_type  = assert(result:match("^(%d+),(.*)"))
    return response(tonumber(code), content_type, content)
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, agent)
    return setmetatable(class.new(agent), metatable)
  end;
})
