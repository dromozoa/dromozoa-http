#! /usr/bin/env perl

# Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

use strict;
use warnings;
use CGI;
use JSON;

my $cgi = CGI->new;

my $request_uri = $cgi->request_uri;

my %reason_3xx = (
  "301" => "Moved Permanently",
  "302" => "Found",
  "307" => "Temporary Redirect",
  "308" => "Permanent Redirect",
);

if ($request_uri =~ m{\.cgi/(301|302|307|308)/(.*)$}) {
  my $code = $1;
  my $uri = $2;
  print $cgi->redirect(-uri => $uri, -status => "$code $reason_3xx{$code}");
  exit;
}

my $set_cookie;
if ($request_uri =~ m{\.cgi/set-cookie/(.*?)/(.*)$}) {
  $set_cookie = $cgi->cookie(-name => $1, -value => $2);
}

my $result = {
  request_method => $cgi->request_method,
  request_uri => $request_uri,
  content_type => $cgi->content_type,
  env => \%ENV,
};

if (defined $cgi->param("POSTDATA")) {
  $result->{content} = $cgi->param("POSTDATA");
} elsif (defined $cgi->param("PUTDATA")) {
  $result->{content} = $cgi->param("PUTDATA");
} else {
  my %params;
  foreach my $name ($cgi->param) {
    my @values = $cgi->param($name);
    foreach my $value (@values) {
      my $info = $cgi->uploadInfo($value);
      if ($info) {
        $value = {
          content => join("", <$value>),
          content_type => $info->{"Content-Type"},
          content_disposition => $info->{"Content-Disposition"},
        };
      }
    }
    ${params}{$name} = \@values;
  }
  if (%params) {
    $result->{params} = \%params;
  }
}

my %cookies;
foreach my $name ($cgi->cookie) {
  $cookies{$name} = $cgi->cookie($name);
}
if (%cookies) {
  $result->{cookies} = \%cookies;
}

if ($set_cookie) {
  print $cgi->header(-type => "application/json", -charset => "UTF-8", -cookie => $set_cookie)
} else {
  print $cgi->header(-type => "application/json", -charset => "UTF-8")
}

print JSON->new->encode($result);
