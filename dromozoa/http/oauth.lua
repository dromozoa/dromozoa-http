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

local base64 = require "dromozoa.commons.base64"
local random_bytes = require "dromozoa.commons.random_bytes"

local class = {}

function class.new(oauth_consumer_key, oauth_token)
  return {
    oauth_consumer_key = oauth_consumer_key;
    oauth_token = oauth_token;
  }
end

function class:reset(oauth_timestamp, oauth_nonce)
  if oauth_timestamp == nil then
    oauth_timestamp = os.time()
  end
  if oauth_nonce == nil then
    oauth_nonce = base64.encode_url(random_bytes(32))
  end
  self.oauth_timestamp = oauth_timestamp
  self.oauth_nonce = oauth_nonce
  return self
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_)
    return setmetatable(class.new(), metatable)
  end;
})
