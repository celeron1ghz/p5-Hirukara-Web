use utf8;
use strict;
use t::Util;
use Test::More tests => 5;

my $m = create_mock_object;
{
    local $m->{exhibition} = 'ComicMarket999';
    $m->run_command('assign_list.create' => { day => 1, run_by => "foo" });
}
{
    local $m->{exhibition} = 'fuga';
    $m->run_command('assign_list.create' => { day => 1, run_by => "bar" });
}
delete_cached_log $m;

my $list = $m->db->single_by_id(assign_list => 1);

subtest "create success on empty circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [], run_by =>'moge' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 0, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign",0,"exist_assign",0,"run_by","moge"]',
        message_id => '割り当てを作成しました。 (assign_list_id=1, created_assign=, exist_assign=, run_by=moge)',
        circle_id  => undef,
        member_id  => undef,
    };
};

subtest "create success on only new circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,3,4,5 ], run_by => 'fuga' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 5, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=5, exist_assign=, run_by=fuga)",
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign","5","exist_assign",0,"run_by","fuga"]',
    };
};

subtest "create success on new and exist circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,7,8,9 ], run_by => 'piyo' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 3, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=3, exist_assign=2, run_by=piyo)",
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign","3","exist_assign","2","run_by","piyo"]',
    };
};

subtest "create success on only exist circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ 1,2,3,4,5,7,8,9 ], run_by => 'moge' });
    ok $ret, "object returned on member create ok";
    isa_ok $ret, "ARRAY";
    is @$ret, 0, "empty array returned";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => "割り当てを作成しました。 (assign_list_id=1, created_assign=, exist_assign=8, run_by=moge)",
        parameters => '["割り当てを作成しました。","assign_list_id","1","created_assign",0,"exist_assign","8","run_by","moge"]',
    };
};

#subtest "select assign ok" => sub {
#    plan tests => 5;
#    my @ret = $m->run_command('assign.search' => { exhibition => "" })->all;
#    is @ret, 2, "return count ok";
#
#    my $a2 = $ret[1];
#    is $a2->id,    2, "id ok";
#    is $a2->count, 0, "assign count ok";
#
#    my $a1 = $ret[0];
#    is $a1->id,    1, "id ok";
#    is $a1->count, 8, "assign count ok";
#};

subtest "exhibition specified select ok" => sub {
    plan tests => 2;
    local $m->{exhibition} = 'ComicMarket999';
    my @ret = $m->run_command('assign.search' => {  })->all;
    #my @ret = $m->run_command('assign.search' => { exhibition => 'ComicMarket999' })->all;
    is @ret, 1, "return count ok";

    my $a1 = $ret[0];
    is $a1->id,    1, "id ok";
    #is $a1->assign_count, 8, "assign count ok";
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
