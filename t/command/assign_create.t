use utf8;
use strict;
use t::Util;
use Test::More tests => 6;

my $m = create_mock_object;
my @cid;
{
    local $m->{exhibition} = 'ComicMarket999';
    $m->run_command('assign_list.create' => { day => 1, run_by => "foo" });
}
{
    local $m->{exhibition} = 'fuga';
    $m->run_command('assign_list.create' => { day => 1, run_by => "bar" });
}
{
    for (1 .. 5)   {
        my $c = create_mock_circle $m, comiket_no => 'ComicMarket999', circle_name => "circle $_";
        push @cid, $c->id;
    }

    for (6 .. 10)   {
        my $c = create_mock_circle $m, comiket_no => 'fuga', circle_name => "circle $_";
        push @cid, $c->id;
    }
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

subtest "error on not exist circle" => sub {
    plan tests => 2;
    exception_ok {
        $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [123], run_by =>'moge' });
    } 'Hirukara::DB::NoSuchRecordException', qr/^データが存在しません。\(table=circle, id=123, mid=moge\)/;
};


subtest "create success on only new circle_ids" => sub {
    plan tests => 5;
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ map { $cid[$_] } 1,2,3,4,5 ], run_by => 'fuga' });
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
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ map { $cid[$_] } 1,2,7,8,9 ], run_by => 'piyo' });
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
    my $ret = $m->run_command('assign.create' => { assign_list_id => $list->id, circle_ids => [ map { $cid[$_] } 1,2,3,4,5,7,8,9 ], run_by => 'moge' });
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
