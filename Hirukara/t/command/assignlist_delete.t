use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use Encode;

my $m = create_mock_object;

supress_log {
    $m->run_command('assign_list.create' => { exhibition => 'mogefuga', member_id => '' });
    $m->run_command('assign_list.create' => { exhibition => 'piyopiyo', member_id => '' });
    $m->run_command('assign_list.create' => { exhibition => 'foobar',   member_id => '' });
    $m->run_command('assign.create' => { circle_ids => [123], assign_list_id => 1 });
    delete_actionlog_ok $m, 4;
};

subtest "assign list delete fail on assign exists" => sub {
    plan tests => 5;

    output_ok {
        exception_ok { $m->run_command('assign_list.delete' => { assign_list_id => 1, member_id => 'moge' }) }
            "Hirukara::AssignList::AssignExistException"
            , qr/割当リスト内にまだ割当が存在します。/
            , "exception thrown on assign exist yet";
    } qr/\[INFO\] 割当リストにまだ割当が存在します。 \(assign_list_id=1, name=新規割当リスト, メンバー名=moge\)/;
 
    actionlog_ok $m;
    delete_actionlog_ok $m, 0;
};

subtest "assign list delete ok on empty list" => sub {
    plan tests => 3;

    output_ok { $m->run_command('assign_list.delete' => { assign_list_id => 2, member_id => 'moge' }) }
        qr/\[INFO\] 割り当てリストを削除しました。 \(assign_list_id=2, name=新規割当リスト, メンバー名=moge\)/;
 
    actionlog_ok $m, { message_id => '割り当てリストを削除しました。 (assign_list_id=2, name=新規割当リスト, メンバー名=moge)', circle_id => undef };
    delete_actionlog_ok $m, 1;
};

subtest "assign list delete ok on being empty list" => sub {
    plan tests => 4;

    output_ok { $m->run_command('assign.delete' => { id => 1, member_id => 'moge' }) }
        qr/\[INFO\] 割り当てを削除しました。 \(id=1, メンバー名=moge, サークル名=UNKNOWN\(123\)\)/;

    output_ok { $m->run_command('assign_list.delete' => { assign_list_id => 2, member_id => 'moge' }) }
        qr/\[INFO\] 割り当てリストを削除しました。 \(assign_list_id=2, name=, メンバー名=moge\)/;
 
    actionlog_ok $m
        , { message_id => '割り当てリストを削除しました。 (assign_list_id=2, name=, メンバー名=moge)', circle_id => undef },
        , { message_id => '割り当てを削除しました。 (id=1, メンバー名=moge, サークル名=UNKNOWN(123))', circle_id => 123 };

    delete_actionlog_ok $m, 2;
};
