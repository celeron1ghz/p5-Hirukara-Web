use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use Encode;

my $m = create_mock_object;

supress_log {
    $m->run_command(assignlist_create => { exhibition => 'mogefuga' });
};


subtest "assign_list value ok" => sub {
    plan tests => 7;
    my $ret = $m->run_command(assignlist_single => { id => 1 });
    ok $ret, "member exist";
    is $ret->id,         '1', 'id ok';
    is $ret->name,       'mogefuga 割り当てリスト', 'name ok';
    is $ret->member_id,  undef, 'comiket_no ok';
    is $ret->comiket_no, 'mogefuga', 'comiket_no ok';

    actionlog_ok $m, { message_id => '割り当てリストを作成しました。', circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "both member_id and name updated" => sub {
    plan tests => 7;
    output_ok {
        my $ret = $m->run_command(assignlist_update => {
            assign_id        => 1,
            member_id        => 'mogemoge',
            assign_member_id => 'fugafuga',
            assign_name      => 'assign name1'
        });
    } qr/\[INFO\] 割り当てリストのメンバーを更新しました。 \(assign_id=1, member_id=mogemoge, before_member=, after_member=fugafuga\)/
     ,qr/\[INFO\] 割り当てリストのリスト名を更新しました。 \(assign_id=1, member_id=mogemoge, before_name=mogefuga 割り当てリスト, after_name=assign name1\)/;

    ok my $ret = $m->run_command(assignlist_single => { id => 1 }), "assign_list ok";
    is $ret->member_id, 'fugafuga',     'member_id ok';
    is $ret->name,      'assign name1', 'name ok';

    actionlog_ok $m
        , { message_id => '割り当てリストのリスト名を更新しました。', circle_id => undef }
        , { message_id => '割り当てリストのメンバーを更新しました。', circle_id => undef };
    delete_actionlog_ok $m, 2;
};


subtest "only member_id updated" => sub {
    plan tests => 6;
    output_ok {
        my $ret = $m->run_command(assignlist_update => {
            assign_id        => 1,
            member_id        => 'mogemoge',
            assign_member_id => '1122334455',
            assign_name      => 'assign name1'
        });
    } qr/\[INFO\] 割り当てリストのメンバーを更新しました。 \(assign_id=1, member_id=mogemoge, before_member=fugafuga, after_member=1122334455\)/;

    ok my $ret = $m->run_command(assignlist_single => { id => 1 }), "assign_list ok";
    is $ret->member_id, '1122334455',   'member_id ok';
    is $ret->name,      'assign name1', 'name ok';

    actionlog_ok $m, { message_id => '割り当てリストのメンバーを更新しました。', circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "only name updated" => sub {
    plan tests => 6;
    output_ok {
        my $ret = $m->run_command(assignlist_update => {
            database         => $m->database,
            assign_id        => 1,
            member_id        => 'mogemoge',
            assign_member_id => '1122334455',
            assign_name      => '5566778899'
        });
    } qr/\[INFO\] 割り当てリストのリスト名を更新しました。 \(assign_id=1, member_id=mogemoge, before_name=assign name1, after_name=5566778899\)/;

    ok my $ret = $m->run_command(assignlist_single => { id => 1 }), "assign_list ok";
    is $ret->member_id, '1122334455', 'member_id ok';
    is $ret->name,      '5566778899', 'name ok';

    actionlog_ok $m, { message_id => '割り当てリストのリスト名を更新しました。', circle_id => undef };
    delete_actionlog_ok $m, 1;
};
