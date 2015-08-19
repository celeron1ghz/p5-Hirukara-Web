use utf8;
use strict;
use t::Util;
use Test::More tests => 14;
use Test::Exception;

my $m = create_mock_object;
my $ID;

subtest "creating circle" => sub {
    plan tests => 1;

    my $c = $m->run_command(circle_create => {
        comiket_no    => "aa",
        day           => "bb",
        circle_sym    => "cc",
        circle_num    => "dd",
        circle_flag   => "ee",
        circle_name   => "ff",
        circle_author => "author",
        area          => "area",
        circlems      => "circlems",
        url           => "url",
    });

    ok $c, "circle create ok";
    $ID = $c->id;
};

subtest "die on not exist circle specified in create" => sub {
    plan tests => 2;

    throws_ok { $m->run_command(checklist_create => { member_id => "moge", circle_id => "fuga" }) }
        "Hirukara::Circle::CircleNotFoundException",
        "die on specify not exist circle";

    actionlog_ok $m;
};

subtest "die on not exist circle specified in delete" => sub {
    plan tests => 2;

    throws_ok { $m->run_command(checklist_delete => { member_id => "moge", circle_id => "fuga", }) }
        "Hirukara::Circle::CircleNotFoundException",
        "die on specify not exist circle";

    actionlog_ok $m;
};

subtest "create checklist" => sub {
    plan tests => 5;

    output_ok {
        my $ret = $m->run_command(checklist_create => { member_id => "moge", circle_id => $ID });
        isa_ok $ret, "Hirukara::Database::Row::Checklist";
        is $ret->member_id, "moge", "member_id ok";
        is $ret->circle_id, $ID,    "circle_id ok";
    } qr/\[INFO\] チェックリストを作成しました。 \(member_id=moge, circle_id=$ID, circle_name=ff\)/;

    actionlog_ok $m, { message_id => q/チェックリストを作成しました。/, circle_id => $ID };
};

subtest "duplicate create checklist fail" => sub {
    plan tests => 3;

    output_ok {
        my $ret = $m->run_command(checklist_create => { member_id => "moge", circle_id => $ID });
        ok !$ret, "not created";
    } qr/^$/;

    actionlog_ok $m, { message_id => q/チェックリストを作成しました。/, circle_id => $ID };
};


subtest "not exist checklist get fail" => sub {
    plan tests => 1;
    my $ret = $m->run_command(checklist_single => { member_id => "9999", circle_id => "9090" });
    ok !$ret, "check list not return";
};

subtest "exist checklist returned" => sub {
    plan tests => 3;
    my $ret = $m->run_command(checklist_single => { member_id => "moge", circle_id => $ID });
    isa_ok $ret, "Hirukara::Database::Row::Checklist";
    is $ret->member_id, "moge", "member_id ok";
    is $ret->circle_id, $ID,    "circle_id ok";
};


subtest "checklist no update on not specify" => sub {
    plan tests => 5;
    output_ok { $m->run_command(checklist_update => { member_id => "moge", circle_id => "1122" }) } qr/^$/;

    my $ret = $m->run_command(checklist_single => { member_id => "moge", circle_id => $ID });
    is $ret->count,   1, "count ok";
    is $ret->comment, undef, "comment ok";

    actionlog_ok $m, { message_id => q/チェックリストを作成しました。/, circle_id => $ID };
    delete_actionlog_ok $m, 1;
};

subtest "updating checklist count" => sub {
    plan tests => 5;
    output_ok { $m->run_command(checklist_update => { member_id => "moge", circle_id => $ID, count => 12, }) }
        qr/\[INFO\] チェックリストの冊数を更新しました。 \(circle_id=$ID, circle_name=ff, member_id=moge, before_cnt=1, after_cnt=12\)/;

    my $ret = $m->run_command(checklist_single => { member_id => "moge", circle_id => $ID });
    is $ret->count,   12, "count ok";
    is $ret->comment, undef, "comment ok";

    actionlog_ok $m, { message_id => q/チェックリストの冊数を更新しました。/, circle_id => $ID };
    delete_actionlog_ok $m, 1;
};

subtest "updating checklist comment" => sub {
    plan tests => 5;
    output_ok { $m->run_command(checklist_update => { member_id => "moge", circle_id => $ID, comment => "piyopiyo" }) }
        qr/\[INFO\] チェックリストのコメントを更新しました。 \(circle_id=$ID, circle_name=ff, member_id=moge\)/;

    my $ret = $m->run_command(checklist_single => { member_id => "moge", circle_id => $ID });
    is $ret->count,   12,         "count ok";
    is $ret->comment, "piyopiyo", "comment ok";

    actionlog_ok $m, { message_id => q/チェックリストのコメントを更新しました。/, circle_id => $ID };
    delete_actionlog_ok $m, 1;
};

subtest "updating empty comment" => sub {
    plan tests => 5;
    output_ok { $m->run_command(checklist_update => { member_id => "moge", circle_id => $ID, comment => "" }) }
        qr/\[INFO\] チェックリストのコメントを更新しました。 \(circle_id=77ca48c9876d9e6c2abad3798b589664, circle_name=ff, member_id=moge\)/;

    my $ret = $m->run_command(checklist_single => { member_id => "moge", circle_id => $ID });
    is $ret->count,   12, "count ok";
    is $ret->comment, "", "comment ok";

    actionlog_ok $m, { message_id => q/チェックリストのコメントを更新しました。/, circle_id => $ID };
    delete_actionlog_ok $m, 1;
};

subtest "updating both checklist count and comment" => sub {
    plan tests => 6;
    output_ok { my $ret = $m->run_command(checklist_update => { member_id => "moge", circle_id => $ID, count => "99", comment => "mogefuga" }) }
        qr/\[INFO\] チェックリストの冊数を更新しました。 \(circle_id=$ID, circle_name=ff, member_id=moge, before_cnt=12, after_cnt=99\)/,
        qr/\[INFO\] チェックリストのコメントを更新しました。 \(circle_id=$ID, circle_name=ff, member_id=moge\)/;

    my $ret = $m->run_command(checklist_single => { member_id => "moge", circle_id => $ID });
    is $ret->count,   99,         "count ok";
    is $ret->comment, "mogefuga", "comment ok";

    actionlog_ok $m
        , { message_id => q/チェックリストのコメントを更新しました。/, circle_id => $ID }
        , { message_id => q/チェックリストの冊数を更新しました。/, circle_id => $ID };
    delete_actionlog_ok $m, 2;
};


subtest "not exist checklist deleting" => sub {
    plan tests => 4;
    output_ok {
        my $ret = $m->run_command(checklist_delete => { member_id => "6666", circle_id => $ID });
        ok !$ret, "no return on not exist checklist";
    } qr/\[INFO\] チェックリストを削除しました。 \(circle_id=$ID, circle_name=ff, member_id=6666, count=0\)/;

    actionlog_ok $m, { message_id => q/チェックリストを削除しました。/, circle_id => $ID };
    delete_actionlog_ok $m, 1;
};

subtest "exist checklist deleting" => sub {
    plan tests => 4;
    output_ok {
        my $ret = $m->run_command(checklist_delete => { member_id => "moge", circle_id => $ID });
        is $ret, 1, "deleted count ok";
    } qr/\[INFO\] チェックリストを削除しました。 \(circle_id=$ID, circle_name=ff, member_id=moge, count=1\)/;

    actionlog_ok $m, { message_id => q/チェックリストを削除しました。/, circle_id => $ID };
    delete_actionlog_ok $m, 1;
};
