use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Test::Time::At;
use Hirukara::Logger;
use Time::Piece;
use WebService::Slack::WebApi;
use LWP::UserAgent;
use Test::Mock::LWP;

my $slack = WebService::Slack::WebApi->new(token => 'aaa');
my $m     = create_mock_object;
my $now   = localtime;
my $with_slack    = Hirukara::Logger->new(database => $m->database, slack => $slack);
my $without_slack = Hirukara::Logger->new(database => $m->database);

subtest "info() ok" => sub_at {
    plan tests => 5;
    my $date = localtime->datetime;

    output_ok { $without_slack->info() }
        qr!^$date \[INFO\]  at lib/Hirukara/Logger.pm line 21\n$!;

    output_ok { $without_slack->info("") }
        qr!^$date \[INFO\]  at lib/Hirukara/Logger.pm line 21\n$!;

    output_ok { $without_slack->info("べろべろ") }
        qr!^$date \[INFO\] べろべろ at lib/Hirukara/Logger.pm line 21\n$!;

    output_ok { $without_slack->info("べろべろ", [ mogemoge => 'fugafuga' ]) }
        qr!^$date \[INFO\] べろべろ \(mogemoge=fugafuga\) at lib/Hirukara/Logger.pm line 21\n$!;

    delete_actionlog_ok $m, 0;
} $now;


subtest "ainfo() without optional args ok" => sub_at {
    plan tests => 3;
    my $date = localtime->datetime;

    output_ok { $without_slack->ainfo("べろべろ") }
        qr!^$date \[INFO\] べろべろ at lib/Hirukara/Logger.pm line 21\n$!;

    is_deeply $m->database->single('action_log')->get_columns, {
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
        parameters => '{}',
        circle_id  => undef,
        message_id => 'べろべろ',
        id         => 1,
    };

    delete_actionlog_ok $m, 1;
} $now;

subtest "ainfo() with optional args ok" => sub_at {
    plan tests => 3;
    my $date = localtime->datetime;

    output_ok { $without_slack->ainfo("ふがふが", [ moge => 'fuga' ]) }
        qr!^$date \[INFO\] ふがふが \(moge=fuga\) at lib/Hirukara/Logger.pm line 21\n$!;

    is_deeply $m->database->single('action_log')->get_columns, {
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
        parameters => '{}',
        circle_id  => undef,
        message_id => 'ふがふが',
        id         => 1,
    };

    delete_actionlog_ok $m, 1;
} $now;

## TODO: test with slack object
