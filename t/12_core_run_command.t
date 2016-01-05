use strict;
use t::Util;
use Test::More tests => 2;
use Test::Exception;
use Hirukara;

my $m = create_mock_object;

subtest "Hirukara->run_command test" => sub {
    plan tests => 7;

    exception_ok { $m->run_command }
        "Hirukara::CLI::ClassLoadFailException", qr/^args is empty/;

    exception_ok { $m->run_command("moge") }
        "Hirukara::CLI::ClassLoadFailException", qr!^Error on loading 'moge' \(Can't locate Hirukara/Command/Moge.pm in \@INC!;

    exception_ok { $m->run_command("exporter") }
        "Hirukara::CLI::ClassLoadFailException", qr!^Error on loading 'exporter' \(Hirukara::Command::Exporter is not a command class\)!;

    lives_ok  { $m->run_command("action_log.select") } "action_log.select work with no error"
};

subtest "Hirukara->run_command_with_options normal test" => sub {
    plan tests => 6;

    exception_ok { $m->run_command_with_options }
        "Hirukara::CLI::ClassLoadFailException", qr!Usage: t/12_core_run_command.t <command name> \[<args>\.\.\.\]!;

    exception_ok { $m->run_command_with_options("moge") }
        "Hirukara::CLI::ClassLoadFailException", qr!^Error on loading 'moge' \(Can't locate Hirukara/Command/Moge.pm in \@INC!;

    exception_ok { $m->run_command_with_options("exporter") }
        "Hirukara::CLI::ClassLoadFailException", qr!^Error on loading 'exporter' \(Hirukara::Command::Exporter is not a command class\)!;
};
