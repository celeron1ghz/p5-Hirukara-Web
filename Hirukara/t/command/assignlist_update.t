use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Encode;
use Test::Time::At;

my $m = create_mock_object;
do_at { $m->run_command('assign_list.create' => { exhibition => 'mogefuga', member_id => '' }) } 1234567890;
delete_cached_log $m;

subtest "both member_id and name updated" => sub {
    plan tests => 3;
    $m->run_command('assign_list.update' => {
        assign_id        => 1,
        member_id        => 'mogemoge',
        assign_member_id => 'fugafuga',
        assign_name      => 'assign name1'
    });

    my $ret = $m->run_command('assign_list.single' => { id => 1 }), "assign_list ok";
    is_deeply $ret->get_columns, {
        id         => 1,
        member_id => 'fugafuga',
        name      => 'assign name1',
        comiket_no => 'mogefuga',
        created_at => 1234567890,
    };

    test_actionlog_ok $m
        , {
            id         => 1,
            circle_id  => undef,
            message_id => '割り当てリストのメンバーを更新しました。 (id=1, メンバー名=mogemoge, before_member=, after_member=fugafuga)',
            parameters => '["割り当てリストのメンバーを更新しました。","id",1,"member_id","mogemoge","before_member","","after_member","fugafuga"]',
        },{
            id         => 2,
            circle_id  => undef,
            message_id => '割り当てリストのリスト名を更新しました。 (id=1, メンバー名=mogemoge, before_name=新規割当リスト, after_name=assign name1)',
            parameters => '["割り当てリストのリスト名を更新しました。","id",1,"member_id","mogemoge","before_name","新規割当リスト","after_name","assign name1"]',
        };
};

subtest "only member_id updated" => sub {
    plan tests => 3;
    $m->run_command('assign_list.update' => {
        assign_id        => 1,
        member_id        => 'mogemoge',
        assign_member_id => '1122334455',
        assign_name      => 'assign name1',
    });

    my $ret = $m->run_command('assign_list.single' => { id => 1 }), "assign_list ok";
    is_deeply $ret->get_columns, {
        id         => 1,
        member_id  => '1122334455',
        name       => 'assign name1',
        comiket_no => 'mogefuga',
        created_at => 1234567890,
    };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => '割り当てリストのメンバーを更新しました。 (id=1, メンバー名=mogemoge, before_member=fugafuga, after_member=1122334455)',
        parameters => '["割り当てリストのメンバーを更新しました。","id",1,"member_id","mogemoge","before_member","fugafuga","after_member","1122334455"]',
    };
};

subtest "only name updated" => sub {
    plan tests => 3;
    $m->run_command('assign_list.update' => {
        assign_id        => 1,
        member_id        => 'mogemoge',
        assign_member_id => '1122334455',
        assign_name      => '5566778899'
    });

    my $ret = $m->run_command('assign_list.single' => { id => 1 }), "assign_list ok";
    is_deeply $ret->get_columns, {
        id         => 1,
        name       => '5566778899',
        member_id  => '1122334455',
        comiket_no => 'mogefuga',
        created_at => 1234567890,
    };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => '割り当てリストのリスト名を更新しました。 (id=1, メンバー名=mogemoge, before_name=assign name1, after_name=5566778899)',
        parameters => '["割り当てリストのリスト名を更新しました。","id",1,"member_id","mogemoge","before_name","assign name1","after_name","5566778899"]',
    };
};
