use utf8;
use strict;
use t::Util;
use Test::More tests => 6;
use Test::Time::At;
use Time::Piece;

my $m = create_mock_object;
my @notices;
my $old1;
my $old2;

subtest "create notice without id ok" => sub_at {
    plan tests => 3;
    my $now = localtime;
    my $ret = $m->run_command('notice.update' => { member_id => 'mogemoge', title => "title 1", text => 'fugafuga' });

    unshift @notices, my $data = {
        id         => 1,
        key        => 1234567000,
        member_id  => "mogemoge",
        title      => "title 1",
        text       => "fugafuga",
        created_at => 1234567000,
    };

    is_deeply $ret->get_columns, $data, "data structure ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => '告知を作成しました。 (id=1, key=1234567000, member_id=mogemoge, title=title 1, text_length=8)',
        parameters => '["告知を作成しました。","id","1","key","1234567000","member_id","mogemoge","title","title 1","text_length","8"]',
    };
} 1234567000;

subtest "create notice with id ok" => sub_at {
    plan tests => 3;
    my $ret = $m->run_command('notice.update' => { key => "1234568000", member_id => 'moge', title => "title 2", text => 'fuga' });

    unshift @notices, $old2 = {
        id         => 2,
        key        => 1234568000,
        member_id  => "moge",
        title      => "title 2",
        text       => "fuga",
        created_at => 1234568000,
    };

    is_deeply $ret->get_columns, $old2, "data structure ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => '告知を更新しました。 (id=2, key=1234568000, member_id=moge, title=title 2, text_length=4)',
        parameters => '["告知を更新しました。","id","2","key","1234568000","member_id","moge","title","title 2","text_length","4"]',
    };
} 1234568000;

subtest "notice select ok" => sub_at {
    plan tests => 1;
    my $ret = $m->run_command('notice.select');
    is_deeply [map { $_->get_columns } @$ret], \@notices, "data structure is ok";
} 1234568000;

subtest "add new notice and that is selected" => sub_at {
    plan tests => 3;
    $m->run_command('notice.update' => { key => "1234568000", member_id => 'mogumogu', title => "title 333", text => 'nemui' });

    my $ret = $m->run_command('notice.select');
    $old1 = $notices[0] = {
        id         => "3",
        key        => 1234568000,
        title      => "title 333",
        text       => "nemui",
        member_id  => "mogumogu",
        created_at => 1234568500,
    };

    is_deeply [map { $_->get_columns } @$ret], \@notices, "data structure is ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => '告知を更新しました。 (id=3, key=1234568000, member_id=mogumogu, title=title 333, text_length=5)',
        parameters => '["告知を更新しました。","id","3","key","1234568000","member_id","mogumogu","title","title 333","text_length","5"]',
    };
} 1234568500;

subtest "add new notice and that is selected" => sub_at {
    plan tests => 3;
    $m->run_command('notice.update' => { key => "1234569000", member_id => 'berobero', title => "title 4444", text => 'zuzuzu' });

    my $ret = $m->run_command('notice.select');
    unshift @notices, my $data = {
            id         => "4",
            key        => 1234569000,
            title      => "title 4444",
            text       => "zuzuzu",
            member_id  => "berobero",
            created_at => 1234569000,
    };

    is_deeply [map { $_->get_columns } @$ret], \@notices, "data structure is ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => '告知を更新しました。 (id=4, key=1234569000, member_id=berobero, title=title 4444, text_length=6)',
        parameters => '["告知を更新しました。","id","4","key","1234569000","member_id","berobero","title","title 4444","text_length","6"]',
    };
} 1234569000;

subtest "notice_single works" => sub_at {
    plan tests => 1;
    my $ret = $m->run_command('notice.single' => { key => 1234568000 });
    is_deeply [ map { $_->get_columns } @$ret ], [ $old1,$old2 ], "data structure is ok";
} 1234569000;
