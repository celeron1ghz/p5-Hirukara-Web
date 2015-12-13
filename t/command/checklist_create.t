use utf8;
use strict;
use t::Util;
use Test::More tests => 14;
use Test::Exception;
use Test::Time::At;

my $m = create_mock_object;
my $ID;

subtest "creating circle" => sub {
    plan tests => 1;
    my $c = create_mock_circle $m;
    ok $c, "circle create ok";
    $ID = $c->id;
    delete_cached_log $m;
};

subtest "die on not exist circle specified in create" => sub {
    plan tests => 3;
    throws_ok { $m->run_command('checklist.create' => { member_id => "moge", circle_id => "fuga" }) }
        "Hirukara::Circle::CircleNotFoundException",
        "die on specify not exist circle";
    test_actionlog_ok $m;
};

subtest "die on not exist circle specified in delete" => sub {
    plan tests => 3;
    throws_ok { $m->run_command('checklist.delete' => { member_id => "moge", circle_id => "fuga", }) }
        "Hirukara::Circle::CircleNotFoundException",
        "die on specify not exist circle";
    test_actionlog_ok $m;
};

subtest "create checklist" => sub_at {
    plan tests => 4;
    my $ret = $m->run_command('checklist.create' => { member_id => "moge", circle_id => $ID });
    isa_ok $ret, "Hirukara::Database::Row::Checklist";
    is_deeply $ret->get_columns, {
        id         => 1,
        member_id  => 'moge',
        circle_id  => $ID,
        count      => 1,
        comment    => undef,
        created_at => 1234567890,
    };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle / author (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID","member_id","moge"]!,
    };
} 1234567890;

subtest "duplicate create checklist fail" => sub {
    plan tests => 3;
    my $ret = $m->run_command('checklist.create' => { member_id => "moge", circle_id => $ID });
    ok !$ret, "not created";

    test_actionlog_ok $m;
};

subtest "not exist checklist get fail" => sub {
    plan tests => 1;
    my $ret = $m->run_command('checklist.single' => { member_id => "9999", circle_id => "9090" });
    ok !$ret, "check list not return";
};

subtest "exist checklist returned" => sub {
    plan tests => 3;
    my $ret = $m->run_command('checklist.single' => { member_id => "moge", circle_id => $ID });
    isa_ok $ret, "Hirukara::Database::Row::Checklist";
    is $ret->member_id, "moge", "member_id ok";
    is $ret->circle_id, $ID,    "circle_id ok";
};

subtest "checklist no update on not specify" => sub {
    plan tests => 4;
    $m->run_command('checklist.update' => { member_id => "moge", circle_id => "1122" });

    my $ret = $m->run_command('checklist.single' => { member_id => "moge", circle_id => $ID });
    is $ret->count,   1, "count ok";
    is $ret->comment, undef, "comment ok";

    test_actionlog_ok $m;
};

subtest "updating checklist count" => sub {
    plan tests => 4;
    $m->run_command('checklist.update' => { member_id => "moge", circle_id => $ID, count => 12, });

    my $ret = $m->run_command('checklist.single' => { member_id => "moge", circle_id => $ID });
    is $ret->count,   12, "count ok";
    is $ret->comment, undef, "comment ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => 'moge',
        message_id => 'チェックリストの冊数を更新しました。: [ComicMarket999] circle / author (member_id=moge, before_cnt=1, after_cnt=12)',
        parameters => qq!["チェックリストの冊数を更新しました。","circle_id","$ID","member_id","moge","before_cnt","1","after_cnt","12"]!,
    };
};

subtest "updating checklist comment" => sub {
    plan tests => 4;
    $m->run_command('checklist.update' => { member_id => "moge", circle_id => $ID, comment => "piyopiyo" });

    my $ret = $m->run_command('checklist.single' => { member_id => "moge", circle_id => $ID });
    is $ret->count,   12,         "count ok";
    is $ret->comment, "piyopiyo", "comment ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => 'moge',
        message_id =>  'チェックリストのコメントを更新しました。: [ComicMarket999] circle / author (member_id=moge)',
        parameters => qq!["チェックリストのコメントを更新しました。","circle_id","$ID","member_id","moge"]!,
    };
};

subtest "updating empty comment" => sub {
    plan tests => 4;
    $m->run_command('checklist.update' => { member_id => "moge", circle_id => $ID, comment => "" });

    my $ret = $m->run_command('checklist.single' => { member_id => "moge", circle_id => $ID });
    is $ret->count,   12, "count ok";
    is $ret->comment, "", "comment ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => 'moge',
        message_id => 'チェックリストのコメントを更新しました。: [ComicMarket999] circle / author (member_id=moge)',
        parameters => qq!["チェックリストのコメントを更新しました。","circle_id","$ID","member_id","moge"]!,
    };
};

subtest "updating both checklist count and comment" => sub {
    plan tests => 4;
    my $ret = $m->run_command('checklist.update' => { member_id => "moge", circle_id => $ID, count => "99", comment => "mogefuga" });

    my $ret = $m->run_command('checklist.single' => { member_id => "moge", circle_id => $ID });
    is $ret->count,   99,         "count ok";
    is $ret->comment, "mogefuga", "comment ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => 'moge',
        message_id => 'チェックリストの冊数を更新しました。: [ComicMarket999] circle / author (member_id=moge, before_cnt=12, after_cnt=99)',
        parameters => qq!["チェックリストの冊数を更新しました。","circle_id","$ID","member_id","moge","before_cnt","12","after_cnt","99"]!,
    }, {
        id         => 2,
        circle_id  => $ID,
        member_id  => 'moge',
        message_id => 'チェックリストのコメントを更新しました。: [ComicMarket999] circle / author (member_id=moge)',
        parameters => qq!["チェックリストのコメントを更新しました。","circle_id","$ID","member_id","moge"]!,
    };
};

subtest "not exist checklist deleting" => sub {
    plan tests => 3;
    my $ret = $m->run_command('checklist.delete' => { member_id => "6666", circle_id => $ID });
    ok !$ret, "no return on not exist checklist";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => '6666',
        message_id => 'チェックリストを削除しました。: [ComicMarket999] circle / author (member_id=6666, count=)',
        parameters => qq!["チェックリストを削除しました。","circle_id","$ID","member_id","6666","count",0]!,
    };
};

subtest "exist checklist deleting" => sub {
    plan tests => 3;
    my $ret = $m->run_command('checklist.delete' => { member_id => "moge", circle_id => $ID });
    is $ret, 1, "deleted count ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => 'moge',
        message_id => 'チェックリストを削除しました。: [ComicMarket999] circle / author (member_id=moge, count=1)',
        parameters => qq!["チェックリストを削除しました。","circle_id","$ID","member_id","moge","count","1"]!,
    };
};
