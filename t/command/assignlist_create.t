use utf8;
use strict;
use t::Util;
use Test::More tests => 1;
use Encode;
use Test::Time::At;

my $m = create_mock_object;

subtest "assign_list create ok" => sub_at {
    plan tests => 4;
    my $ret = $m->run_command('assign_list.create' => { day => 1, run_by => 'piyopiyo' });
    isa_ok $ret, "Hirukara::Database::Row::AssignList";

    my $ret = $m->db->single_by_id(assign_list => 1);
    is_deeply $ret->get_columns, {
        id         => 1,
        name       => '新規割当リスト',
        member_id  => undef,
        comiket_no => 'ComicMarket999',
        day        => 1,
        created_at => 1234567890,
    }, 'data ok';

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => '割り当てリストを作成しました。 (id=1, name=新規割当リスト, comiket_no=ComicMarket999, day=1, run_by=piyopiyo)',
        parameters => '["割り当てリストを作成しました。","id","1","name","新規割当リスト","comiket_no","ComicMarket999","day","1","run_by","piyopiyo"]',
    };
} 1234567890;
