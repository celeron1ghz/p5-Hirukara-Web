use strict;
use t::Util;
use Test::More tests => 3;
use Test::Exception;
use Hirukara::CLI;

subtest "load fail on not exist class" => sub {
    exception_ok {
        supress_log { Hirukara::CLI->run('moge') }
    } "Hirukara::CLI::ClassLoadFailException", qr/'moge' load fail. Reason are below:/;
};

subtest "load fail on not applied Hirukara::Command class" => sub {
    exception_ok {
        supress_log { Hirukara::CLI->run('exhibition') }
    } "Hirukara::CLI::ClassLoadFailException", qr/command 'exhibition' is not a command class/;
};

subtest "load ok" => sub {
    local @ARGV = ('--circle_id' => 'mogemoge');

    lives_ok {
        output_ok { Hirukara::CLI->run("circle_single") } qr/exited. no value returned/;
    } "not die on running command";
};
