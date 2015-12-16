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
local xml = require "dromozoa.xml"
local http = require "dromozoa.http"

local access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
local secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")

local scheme = "https"
local host = "sts.ap-northeast-1.amazonaws.com"
local version = "2011-06-15"

local ua = http:user_agent("dromozoa-http")

local aws4 = http.aws4("ap-northeast-1", "sts", access_key_id)

local uri = http.uri(scheme, host, "/")
  :param({
    Version = version;
    Action = "GetFederationToken";
    Name = "dromozoa";
    Policy = json.encode({
      Version =  "2012-10-17";
      Statement = {
        {
          Sid = "Stmt1",
          Effect = "Allow",
          Action = { "s3:*" };
          Resource = { "*" };
        };
      };
    });
  })
local request = http.request("GET", uri)
aws4:sign_header(request, secret_access_key)
local response = ua:request(request)
print(response.content)
