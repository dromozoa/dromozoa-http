#! /bin/sh -e

# Copyright (C) 2015,2018,2019 Tomoyuki Fujimori <moyu@dromozoa.com>
#
# This file is part of dromozoa-http.
#
# dromozoa-http is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dromozoa-http is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dromozoa-http.  If not, see <http://www.gnu.org/licenses/>.

LUA_PATH="?.lua;;"
export LUA_PATH

case x$AWS_SECRET_ACCESS_KEY in
  x) ;;
  *)
    case X$# in
      X0) lua test/sts "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" >test-credentials.json;;
      *) "$@" test/sts "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" >test-credentials.json;;
    esac;;
esac

for i in test/test*.lua
do
  case X$# in
    X0) lua "$i";;
    *) "$@" "$i";;
  esac
done

rm -f test*.json
