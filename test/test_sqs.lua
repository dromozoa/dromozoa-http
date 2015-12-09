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

local xml = require "dromozoa.commons.xml"
local http = require "dromozoa.http"

local access_key = assert(os.getenv("AWS_ACCESS_KEY"))
local secret_key = assert(os.getenv("AWS_SECRET_KEY"))

local scheme = "https"
local queue = "dromozoa"
local host = "sqs.ap-northeast-1.amazonaws.com"
local version = "2012-11-05"

local ua = http:user_agent()
ua:agent("dromozoa-http")

local aws4 = http.aws4("ap-northeast-1", "sqs")

local uri = http.uri(scheme, host, "/")
    :param("Action", "GetQueueUrl")
    :param("QueueName", queue)
    :param("Version", version)
local request = http.request("GET", uri)
aws4:sign_header(request, access_key, secret_key)
local response = ua:request(request)
assert(response.code == 200)
assert(response.content_type == "text/xml")

local result = xml.decode(response.content)

local NAME = 1
local CONTENT = 3
assert(result[CONTENT][1][NAME] == "GetQueueUrlResult")
assert(result[CONTENT][1][CONTENT][1][NAME] == "QueueUrl")
assert(result[CONTENT][1][CONTENT][1][CONTENT][1] == "https://sqs.ap-northeast-1.amazonaws.com/512093523674/dromozoa")
