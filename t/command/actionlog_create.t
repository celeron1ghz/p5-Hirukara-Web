use utf8;
use strict;
use t::Util;
use Test::More tests => 10;
use Test::Exception;
use Time::Piece;
use_ok 'Hirukara::Command::Actionlog::Select';
use_ok 'Hirukara::Command::Actionlog::Create';

my $m = create_mock_object;

subtest "actionlog invalid args" => sub {
    throws_ok {
        Hirukara::Command::Actionlog::Create->new(database => $m->database, message_id => "moge", parameters => {})->run;
    } qr/actionlog message=moge not found/, 'die on message id not exist';

    throws_ok {
        Hirukara::Command::Actionlog::Create->new(database => $m->database, message_id => "MEMBER_CREATE", parameters => {})->run;
    } qr/key 'member_id' is not exist in args 'parameter'/, 'die on not enough parameter';
};


subtest "actionlog create ok" => sub {
    ok my $log = Hirukara::Command::Actionlog::Create->new(database => $m->database, message_id => "MEMBER_CREATE", parameters => { member_id => 'moge' })->run;
    is $log->id,         1,               "id ok";
    is $log->message_id, "MEMBER_CREATE", "message_id ok";
    is $log->parameters, '{"member_id":"moge"}', "parameters ok";
    is $log->created_at, localtime->strftime("%Y-%m-%d %H:%M:%S");
    ok !$log->circle_id, "circle_id ok";
};


supress_log {
    Hirukara::Command::Actionlog::Create->new(database => $m->database, message_id => "MEMBER_CREATE", parameters => { member_id => $_ })->run for 2 .. 128;
};

sub pager_ok {
    my($pager,$expected) = @_;
    my $got = {};

    while ( my($key,$val) = each %$expected )   {
        $got->{$key} = $pager->$key;
    }

    is_deeply $got, $expected, "pager data ok";
}

subtest "all rows return on specify count=0" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, count => 0)->run;

    pager_ok($ret->{pager}, {
        total_entries    => 128,
        entries_per_page => 10,
        previous_page => undef,
        current_page  => 1,
        next_page     => 2,
        first_page    => 1,
        last_page     => 13,
        first         => 1,
        last          => 10,
    });

    my $logs = $ret->{actionlogs};
    is_deeply [ map { $_->{id} } @$logs ], [ reverse 1 .. 128 ], "given id is ok";
};


subtest "single actionlog test" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, count => 1)->run;

    pager_ok($ret->{pager}, {
        total_entries    => 128,
        entries_per_page => 1,
        previous_page => undef,
        current_page  => 1,
        next_page     => 2,
        first_page    => 1,
        last_page     => 128,
        first         => 1,
        last          => 1,
    });

    my $logs = $ret->{actionlogs};
    is_deeply $logs, [{
        id => 128,
        type => 'メンバーの新規ログイン',
        message => '128 さんが初めてログインしました',
        created_at => localtime->strftime("%Y-%m-%d %H:%M:%S"),
    }], "data ok";
};


subtest "getting specify count actionlog test" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, count => 20)->run;

    pager_ok($ret->{pager}, {
        total_entries    => 128,
        entries_per_page => 20,
        previous_page => undef,
        current_page  => 1,
        next_page     => 2,
        first_page    => 1,
        last_page     => 7,
        first         => 1,
        last          => 20,
    });

    my $logs = $ret->{actionlogs};
    is_deeply [ map { $_->{id} } @$logs ], [ reverse 109 .. 128 ], "given id is ok";
};


subtest "paging test of next page" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, page => 2)->run;

    pager_ok($ret->{pager}, {
        total_entries    => 128,
        entries_per_page => 30,
        previous_page => 1,
        current_page  => 2,
        next_page     => 3,
        first_page    => 1,
        last_page     => 5,
        first         => 31,
        last          => 60,
    });
};

subtest "paging test of last - 1 page" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, page => 4)->run;

    pager_ok($ret->{pager}, {
        total_entries    => 128,
        entries_per_page => 30,
        previous_page => 3,
        current_page  => 4,
        next_page     => 5,
        first_page    => 1,
        last_page     => 5,
        first         => 91,
        last          => 120,
    });
};

subtest "paging test of last page" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, page => 5)->run;

    pager_ok($ret->{pager}, {
        total_entries    => 128,
        entries_per_page => 30,
        previous_page => 4,
        current_page  => 5,
        next_page     => undef,
        first_page    => 1,
        last_page     => 5,
        first         => 121,
        last          => 128,
    });
};
