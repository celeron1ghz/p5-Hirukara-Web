use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Encode;

my $m = create_mock_object;
$m->run_command('assign_list.create' => { exhibition => 'mogefuga', member_id => '' });
$m->run_command('assign_list.create' => { exhibition => 'piyopiyo', member_id => '' });
$m->run_command('assign_list.create' => { exhibition => 'foobar',   member_id => '' });
$m->run_command('assign.create' => { circle_ids => [123], assign_list_id => 1 });
delete_cached_log $m;

subtest "assign list delete fail on assign exists" => sub {
    plan tests => 4;
    exception_ok { $m->run_command('assign_list.delete' => { assign_list_id => 1, member_id => 'moge' }) }
        "Hirukara::AssignList::AssignExistException"
        , qr/割当リスト内にまだ割当が存在します。/
        , "exception thrown on assign exist yet";
 
    test_actionlog_ok $m, {
        id  => 1,
        circle_id => undef,
        member_id  => undef,
        message_id => '割当リストにまだ割当が存在します。 (assign_list_id=1, name=新規割当リスト, member_id=moge)',
        parameters => '["割当リストにまだ割当が存在します。","assign_list_id","1","name","新規割当リスト","member_id","moge"]',
    };
};

subtest "assign list delete ok on empty list" => sub {
    plan tests => 2;
    $m->run_command('assign_list.delete' => { assign_list_id => 2, member_id => 'moge' });
 
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => '割り当てリストを削除しました。 (assign_list_id=2, name=新規割当リスト, member_id=moge)',
        parameters => '["割り当てリストを削除しました。","assign_list_id","2","name","新規割当リスト","member_id","moge"]',
    };
};

subtest "assign list delete ok on being empty list" => sub {
    plan tests => 2;
    $m->run_command('assign.delete' => { id => 1, member_id => 'moge' });
    $m->run_command('assign_list.delete' => { assign_list_id => 2, member_id => 'moge' });
 
    test_actionlog_ok $m
        , {
            id         => 1,
            circle_id  => undef,
            member_id  => undef,
            message_id => '割り当てを削除しました。 (id=1, member_id=moge, circle_id=123)',
            parameters => '["割り当てを削除しました。","id","1","member_id","moge","circle_id","123"]',
        }, {
            id         => 2,
            circle_id  => undef,
            member_id  => undef,
            message_id => '割り当てリストを削除しました。 (assign_list_id=2, name=, member_id=moge)',
            parameters => '["割り当てリストを削除しました。","assign_list_id","2","name",null,"member_id","moge"]',
        };
};
