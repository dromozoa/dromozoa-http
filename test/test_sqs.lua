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

local json = require "dromozoa.commons.json"
local read_file = require "dromozoa.commons.read_file"
local xml = require "dromozoa.xml"
local http = require "dromozoa.http"

local handle = io.open "test-credentials.json"
if not handle then
  os.exit()
end
handle:close()

local credentials = json.decode(assert(read_file("test-credentials.json")))

local scheme = "https"
local queue = "dromozoa"
local host = "sqs.ap-northeast-1.amazonaws.com"
local version = "2012-11-05"

local ua = http.user_agent("dromozoa-http")

local aws4 = http.aws4("ap-northeast-1", "sqs", credentials.access_key_id, credentials.session_token)

local uri = http.uri(scheme, host, "/")
    :param("Action", "GetQueueUrl")
    :param("QueueName", queue)
    :param("Version", version)
local request = http.request("GET", uri)
aws4:sign_header(request, credentials.secret_access_key)
local response = ua:request(request)
assert(response.code == 200)
assert(response.content_type == "text/xml")
local result = xml.decode(response.content)
assert(result:query("GetQueueUrlResult>QueueUrl"):text() == "https://sqs.ap-northeast-1.amazonaws.com/512093523674/dromozoa")
