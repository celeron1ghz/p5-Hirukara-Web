use strict;
use t::Util;
use Test::More tests => 4;
use Test::Exception;
use Hirukara;

my $m = create_mock_object;

subtest "Hirukara->run_command test" => sub {
    plan tests => 5;

    exception_ok { $m->run_command }
        "Hirukara::CLI::ClassLoadFailException", qr/No class name specified in args/;

    exception_ok { $m->run_command("moge") }
        "Hirukara::CLI::ClassLoadFailException", qr/command 'moge' load fail. Reason are below:/;

    lives_ok  { $m->run_command("circle.single", { circle_id => "moge" }) } "circle.single work with no error"
};

subtest "Hirukara->run_command_with_options normal test" => sub {
    plan tests => 4;

    exception_ok { $m->run_command_with_options }
        "Hirukara::CLI::ClassLoadFailException", qr!Usage: t/12_core_run_command.t <command name> \[<args>\.\.\.\]!;

    exception_ok { $m->run_command_with_options("moge") }
        "Hirukara::CLI::ClassLoadFailException", qr/command 'moge' load fail. Reason are below:/;
};

subtest "Hirukara->run_command_with_options die on no \@ARGV" => sub {
    plan tests => 1;
    throws_ok { $m->run_command_with_options("circle.single", { circle_id => "moge" }) }
        qr/Mandatory parameter 'circle_id' missing/;
};

subtest "Hirukara->run_command_with_options ok on \@ARGV" => sub {
    plan tests => 1;
    local @ARGV = ('--circle_id', 'mogemoge');
    lives_ok { $m->run_command_with_options("circle.single") } "circle.single work with no error"
};
