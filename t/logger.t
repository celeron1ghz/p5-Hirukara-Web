use utf8;
use strict;
use t::Util;
use Test::More tests => 6;
use Test::Time::At;
use Hirukara::Logger;
use Time::Piece;
use WebService::Slack::WebApi;
use LWP::UserAgent;
use Test::Mock::LWP;
use Path::Tiny;

my $slack = WebService::Slack::WebApi->new(token => 'aaa');
my $m     = create_mock_object;
my $now   = localtime;
my $with_slack    = Hirukara::Logger->new(database => $m->database, slack => $slack);
my $without_slack = Hirukara::Logger->new(database => $m->database);

my $path = path('lib/Hirukara/Logger.pm')->absolute;
my $callerstr = qq!$path line 63\n!;

subtest "info() ok" => sub_at {
    plan tests => 5;
    my $date = localtime->datetime;

    output_ok { $without_slack->info() }
        qr!^$date \[INFO\]  at $callerstr$!;

    output_ok { $without_slack->info("") }
        qr!^$date \[INFO\]  at $callerstr$!;

    output_ok { $without_slack->info("べろべろ") }
        qr!^$date \[INFO\] べろべろ at $callerstr$!;

    output_ok { $without_slack->info("べろべろ", [ mogemoge => 'fugafuga' ]) }
        qr!^$date \[INFO\] べろべろ \(mogemoge=fugafuga\) at $callerstr$!;

    delete_actionlog_ok $m, 0;
} $now;


subtest "ainfo() without optional args ok" => sub_at {
    plan tests => 3;
    my $date = localtime->datetime;

    output_ok { $without_slack->ainfo("べろべろ") }
        qr!^$date \[INFO\] べろべろ at $callerstr$!;

    is_deeply $m->database->single('action_log')->get_columns, {
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
        parameters => '["べろべろ"]',
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
        qr!^$date \[INFO\] ふがふが \(moge=fuga\) at $callerstr$!;

    is_deeply $m->database->single('action_log')->get_columns, {
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
        parameters => '["ふがふが","moge","fuga"]',
        circle_id  => undef,
        message_id => 'ふがふが (moge=fuga)',
        id         => 1,
    };

    delete_actionlog_ok $m, 1;
} $now;

my @ID;

subtest "preparing data ok" => sub {
    supress_log {
        for (1 .. 2)    {
            my $ret = $m->run_command('circle.create' => {
                comiket_no    => "aa",
                day           => "bb",
                circle_sym    => "cc",
                circle_num    => "dd",
                circle_flag   => "ee",
                circle_name   => "circle $_",
                circle_author => "author",
                area          => "area",
                circlems      => "circlems",
                url           => "url",
            });
    
            push @ID, $ret->id;
        }
    
        $m->run_command('member.create' => {
            id          => '1234',
            member_id   => 'mogemoge',
            member_name => 'もげもげ',
            image_url   => 'url',
        });
    
        delete_actionlog_ok $m, 1;
    }
};

subtest "ainfo() with extract circle ok" => sub_at {
    plan tests => 3;
    my $date = localtime->datetime;

    output_ok { $without_slack->ainfo("ふがふが", [ circle_id => $ID[0] ]) }
        qr!^$date \[INFO\] ふがふが \(サークル名=circle 1 \(author\)\) at $callerstr$!;

    is_deeply $m->database->single('action_log')->get_columns, {
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
        parameters => qq'["ふがふが","circle_id","$ID[0]"]',
        circle_id  => undef,
        message_id => 'ふがふが (サークル名=circle 1 (author))',
        id         => 1,
    };

    delete_actionlog_ok $m, 1;
} $now;

subtest "ainfo() with extract member ok" => sub_at {
    plan tests => 3;
    my $date = localtime->datetime;

    output_ok { $without_slack->ainfo("ふがふが", [ member_id => 'mogemoge' ]) }
        qr!^$date \[INFO\] ふがふが \(メンバー名=もげもげ\(mogemoge\)\) at $callerstr$!;

    is_deeply $m->database->single('action_log')->get_columns, {
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
        parameters => '["ふがふが","member_id","mogemoge"]',
        circle_id  => undef,
        message_id => 'ふがふが (メンバー名=もげもげ(mogemoge))',
        id         => 1,
    };

    delete_actionlog_ok $m, 1;
} $now;

