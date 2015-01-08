use strict;
use t::Util;
use Test::More tests => 4;
use Test::Exception;
use Hirukara;

my $m = create_mock_object;

subtest "Hirukara->run_command test" => sub {
    exception_ok { $m->run_command }
        "Hirukara::CLI::ClassLoadFailException", qr/No class name specified in args/;

    exception_ok { $m->run_command("moge") }
        "Hirukara::CLI::ClassLoadFailException", qr/command 'moge' load fail. Reason are below:/;

    exception_ok { $m->run_command("exhibition") }
        "Hirukara::CLI::ClassLoadFailException", qr/command 'exhibition' is not a command class/;

    lives_ok  { $m->run_command("circle_single", { circle_id => "moge" }) } "circle_single work with no error"
};

subtest "Hirukara->run_command_with_options normal test" => sub {
    exception_ok { $m->run_command_with_options }
        "Hirukara::CLI::ClassLoadFailException", qr/No class name specified in args/;

    exception_ok { $m->run_command_with_options("moge") }
        "Hirukara::CLI::ClassLoadFailException", qr/command 'moge' load fail. Reason are below:/;

    exception_ok { $m->run_command_with_options("exhibition") }
        "Hirukara::CLI::ClassLoadFailException", qr/command 'exhibition' is not a command class/;
};

subtest "Hirukara->run_command_with_options die on no \@ARGV" => sub {
    throws_ok { $m->run_command_with_options("circle_single", { circle_id => "moge" }) }
        qr/Mandatory parameter 'circle_id' missing/;
};

subtest "Hirukara->run_command_with_options ok on \@ARGV" => sub {
    local @ARGV = ('--circle_id', 'mogemoge');
    lives_ok { $m->run_command_with_options("circle_single") } "circle_single work with no error"
};
