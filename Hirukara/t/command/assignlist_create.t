use utf8;
use strict;
use t::Util;
use Test::More tests => 1;
use Encode;

my $m = create_mock_object;

subtest "assign_list create ok" => sub {
    plan tests => 11;
    output_ok {
        my $ret = $m->run_command('assign_list.create' => { exhibition => 'mogefuga', member_id => 'piyopiyo' });
        ok $ret, "object returned on member create ok";
        isa_ok $ret, "Hirukara::Database::Row::AssignList";

    } qr/\[INFO\] 割り当てリストを作成しました。 \(id=1, name=新規割当リスト, comiket_no=mogefuga, メンバー名=piyopiyo\)/;

    ok !$m->run_command('assign_list.single' => { id => 9999 }), "object not returned";

    my $ret = $m->run_command('assign_list.single' => { id => 1 });
    ok $ret, "member exist";
    is $ret->id,         '1', 'id ok';
    is $ret->name,       '新規割当リスト', 'name ok';
    is $ret->comiket_no, 'mogefuga', 'comiket_no ok';
    is $ret->member_id,  undef, 'member_id ok';

    actionlog_ok $m, { message_id => "割り当てリストを作成しました。 (id=1, name=新規割当リスト, comiket_no=mogefuga, メンバー名=piyopiyo)", circle_id => undef };
    delete_actionlog_ok $m, 1;
};
