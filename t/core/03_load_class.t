use strict;
use t::Util;
use Test::More tests => 7;
use Test::Exception;
use Hirukara;

exception_ok { Hirukara->load_class }
    "Hirukara::CLI::ClassLoadFailException", qr/No class name specified in args/;

exception_ok { Hirukara->load_class("moge") }
    "Hirukara::CLI::ClassLoadFailException", qr/command 'moge' load fail. Reason are below:/;

exception_ok { Hirukara->load_class("exhibition") }
    "Hirukara::CLI::ClassLoadFailException", qr/command 'exhibition' is not a command class/;

my $ret = Hirukara->load_class("circle_single");
is $ret, "Hirukara::Command::Circle::Single", "return value is loaded class";
