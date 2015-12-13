use utf8;
use strict;
use t::Util;
use Test::More tests => 6;

my $m = create_mock_object;
$m->run_command('assign_list.create' => { exhibition => 'ComicMarket999', member_id => "foo" });
$m->run_command('assign_list.create' => { exhibition => 'fuga', member_id => "bar" });
delete_cached_log $m;

my $list = $m->run_command('assign_list.single' => { id => 1 });

subtest "create success on empty circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [], member_id =>'moge' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 0, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign",0,"exist_assign",0,"member_id","moge"]',
        message_id => '割り当てを作成しました。 (assign_list_id=1, created_assign=, exist_assign=, member_id=moge)',
        circle_id  => undef,
        member_id  => 'moge',
    };
};

subtest "create success on only new circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,3,4,5 ], member_id => 'fuga' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 5, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'fuga',
        message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=5, exist_assign=, member_id=fuga)",
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign","5","exist_assign",0,"member_id","fuga"]',
    };
};

subtest "create success on new and exist circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,7,8,9 ], member_id => 'piyo' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 3, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'piyo',
        message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=3, exist_assign=2, member_id=piyo)",
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign","3","exist_assign","2","member_id","piyo"]',
    };
};

subtest "create success on only exist circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,3,4,5,7,8,9 ], member_id => 'moge' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 0, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=, exist_assign=8, member_id=moge)",
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign",0,"exist_assign","8","member_id","moge"]',
    };
};

subtest "select assign ok" => sub {
    plan tests => 5;
    my @ret = $m->run_command('assign.search' => { exhibition => "" })->all;
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
    my @ret = $m->run_command('assign.search' => { exhibition => 'ComicMarket999' })->all;
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
