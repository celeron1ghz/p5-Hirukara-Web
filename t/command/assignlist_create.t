use utf8;
use strict;
use t::Util;
use Test::More tests => 1;
use Encode;
use Test::Time::At;

my $m = create_mock_object;

subtest "assign_list create ok" => sub_at {
    plan tests => 4;
    my $ret = $m->run_command('assign_list.create' => { exhibition => 'mogefuga', member_id => 'piyopiyo' });
    isa_ok $ret, "Hirukara::Database::Row::AssignList";

    my $ret = $m->run_command('assign_list.single' => { id => 1 });
    is_deeply $ret->get_columns, {
        id         => 1,
        name       => '新規割当リスト',
        member_id  => undef,
        comiket_no => 'mogefuga',
        created_at => 1234567890,
    }, 'data ok';

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'piyopiyo',
        message_id => '割り当てリストを作成しました。 (id=1, name=新規割当リスト, comiket_no=mogefuga, member_id=piyopiyo)',
        parameters => '["割り当てリストを作成しました。","id","1","name","新規割当リスト","comiket_no","mogefuga","member_id","piyopiyo"]',
    };
} 1234567890;
