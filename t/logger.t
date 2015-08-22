use utf8;
use strict;
use t::Util;
use Test::More tests => 14;
use Test::Time::At;
use Hirukara::Logger;
use Time::Piece;

my $m   = create_mock_object;
my $l   = Hirukara::Logger->new(database => $m->database);
my $now = localtime;

subtest "info() ok" => sub_at {
    plan tests => 5;
    my $date = localtime->datetime;

    output_ok { $l->info() }
        qr!^$date \[INFO\]  at lib/Hirukara/Logger.pm line 20\n$!;

    output_ok { $l->info("") }
        qr!^$date \[INFO\]  at lib/Hirukara/Logger.pm line 20\n$!;

    output_ok { $l->info("べろべろ") }
        qr!^$date \[INFO\] べろべろ at lib/Hirukara/Logger.pm line 20\n$!;

    output_ok { $l->info("べろべろ", [ mogemoge => 'fugafuga' ]) }
        qr!^$date \[INFO\] べろべろ \(mogemoge=fugafuga\) at lib/Hirukara/Logger.pm line 20\n$!;

    delete_actionlog_ok $m, 0;
} $now;


subtest "ainfo() without optional args ok" => sub_at {
    plan tests => 3;
    my $date = localtime->datetime;

    output_ok { $l->ainfo("べろべろ") }
        qr!^$date \[INFO\] べろべろ at lib/Hirukara/Logger.pm line 20\n$!;

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

    output_ok { $l->ainfo("ふがふが", [ moge => 'fuga' ]) }
        qr!^$date \[INFO\] ふがふが \(moge=fuga\) at lib/Hirukara/Logger.pm line 20\n$!;

    is_deeply $m->database->single('action_log')->get_columns, {
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
        parameters => '{}',
        circle_id  => undef,
        message_id => 'ふがふが',
        id         => 1,
    };

    delete_actionlog_ok $m, 1;
} $now;
