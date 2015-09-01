use utf8;
use strict;
use t::Util;
use Test::More tests => 7;

my $m = create_mock_object;

supress_log {
    $m->run_command('assign_list.create' => { exhibition => 'moge', member_id => "foo" });
    $m->run_command('assign_list.create' => { exhibition => 'fuga', member_id => "bar" });
    delete_actionlog_ok $m, 2;
};

my $list = $m->run_command('assign_list.single' => { id => 1 });

subtest "create success on empty circle_ids" => sub {
    plan tests => 6;
    output_ok {
        my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [] });
        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 0, "empty array returned";
    } qr/\[INFO\] 割り当てを作成しました。 \(assign_list_id=1, created_assign=0, exist_assign=0\)/;

    actionlog_ok $m, { message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=0, exist_assign=0)", circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "create success on only new circle_ids" => sub {
    plan tests => 6;
    output_ok {
        my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,3,4,5 ] });
        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 5, "empty array returned";
    } qr/\[INFO\] 割り当てを作成しました。 \(assign_list_id=1, created_assign=5, exist_assign=0\)/;

    actionlog_ok $m, { message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=5, exist_assign=0)", circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "create success on new and exist circle_ids" => sub {
    plan tests => 6;
    output_ok {
        my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,7,8,9 ] });
        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 3, "empty array returned";

    } qr/\[INFO\] 割り当てを作成しました。 \(assign_list_id=1, created_assign=3, exist_assign=2\)/;

    actionlog_ok $m, { message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=3, exist_assign=2)", circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "create success on only exist circle_ids" => sub {
    plan tests => 6;
    output_ok {
        my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,3,4,5,7,8,9 ] });
        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 0, "empty array returned";

    } qr/\[INFO\] 割り当てを作成しました。 \(assign_list_id=1, created_assign=0, exist_assign=8\)/;

    actionlog_ok $m, { message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=0, exist_assign=8)", circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "select assign ok" => sub {
    plan tests => 5;
    my @ret = $m->run_command('assign.search')->all;
    is @ret, 2, "return count ok";

    my $a2 = $ret[1];
    is $a2->id,    2, "id ok";
    is $a2->count, 0, "assign count ok";

    my $a1 = $ret[0];
    is $a1->id,    1, "id ok";
    is $a1->count, 8, "assign count ok";
};


subtest "exhibition specified select ok" => sub {
    plan tests => 3;
    my @ret = $m->run_command('assign.search' => { exhibition => 'moge' })->all;
    is @ret, 1, "return count ok";

    my $a1 = $ret[0];
    is $a1->id,    1, "id ok";
    is $a1->count, 8, "assign count ok";
};


#subtest "member_id specified select ok" => sub {
#    plan tests => 3;
#    my @ret = $m->run_command('assign.search' => { member_id => 'foo' })->all;
#    is @ret, 1, "return count ok";
#
#    my $a1 = $ret[0];
#    is $a1->id,    1, "id ok";
#    is $a1->count, 8, "assign count ok";
#};
