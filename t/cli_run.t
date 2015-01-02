use strict;
use t::Util;
use Test::More tests => 4;
use Test::Exception;
use_ok "Hirukara::CLI";

subtest "load fail on not exist class" => sub {
    throws_ok { Hirukara::CLI->run('moge') }
        qr/'moge' load fail. Reason are below:/, "die on not exist class";
};

subtest "load fail on not applied Hirukara::Command class" => sub {
    throws_ok { Hirukara::CLI->run('exhibition') }
        qr/command 'exhibition' is not a command class/, "die on not a Hirukara::Command class";
};

subtest "load ok" => sub {
    local @ARGV = ('--circle_id' => 'mogemoge');
    lives_ok { Hirukara::CLI->run("circle_single") }
        "not die on running command";
};
