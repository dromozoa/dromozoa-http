rockspec_format = "3.0"
package = "dromozoa-http"
version = "1.12-1"
source = {
  url = "https://github.com/dromozoa/dromozoa-http/archive/v1.12.tar.gz";
  file = "dromozoa-http-1.12.tar.gz";
}
description = {
  summary = "Portable HTTP client";
  license = "GPL-3";
  homepage = "https://github.com/dromozoa/dromozoa-http/";
  maintainer = "Tomoyuki Fujimori <moyu@dromozoa.com>";
}
dependencies = {
  "dromozoa-commons";
}
test = {
  type = "command";
  command = "./test.sh";
}
build = {
  type = "builtin";
  modules = {
    ["dromozoa.http"] = "dromozoa/http.lua";
    ["dromozoa.http.aws4"] = "dromozoa/http/aws4.lua";
    ["dromozoa.http.form"] = "dromozoa/http/form.lua";
    ["dromozoa.http.oauth"] = "dromozoa/http/oauth.lua";
    ["dromozoa.http.parameters"] = "dromozoa/http/parameters.lua";
    ["dromozoa.http.query"] = "dromozoa/http/query.lua";
    ["dromozoa.http.request"] = "dromozoa/http/request.lua";
    ["dromozoa.http.response"] = "dromozoa/http/response.lua";
    ["dromozoa.http.uri"] = "dromozoa/http/uri.lua";
    ["dromozoa.http.user_agent"] = "dromozoa/http/user_agent.lua";
  };
}
