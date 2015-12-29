use strict;
use t::Util;
use Test::More tests => 5;
use Test::Exception;
use Hirukara;

exception_ok { Hirukara->load_class }
    "Hirukara::CLI::ClassLoadFailException", qr/No class name specified in args/;

exception_ok { Hirukara->load_class("moge") }
    "Hirukara::CLI::ClassLoadFailException", qr/command 'moge' load fail. Reason are below:/;

my $ret = Hirukara->load_class("circle.single");
is $ret, "Hirukara::Command::Circle::Single", "return value is loaded class";
