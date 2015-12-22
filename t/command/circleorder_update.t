use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use Test::Time::At;
use Test::Exception;

my $m = create_mock_object;
my $c = create_mock_circle $m;
my $b = do_at {
    $m->run_command('circle_book.create', {
        circle_id  => $c->id,
        member_id  => 'piyopiyo',
        created_by => 'mogemoge',
    });

} 1234567890;

delete_cached_log $m;
my $o;

subtest "error on not exist circle" => sub {
    plan tests => 2;
    exception_ok {
        $m->run_command('circle_order.update', {
            book_id   => '123',
            member_id => 'piyopiyo',
            count     => 11,
        });
    } 'Hirukara::DB::NoSuchRecordException', qr/データが存在しません。\(table=circle_book, id=123\)/
};

subtest "creating new order ok" => sub_at {
    plan tests => 4;
    my $ret = $m->run_command('circle_order.update', {
        book_id    => $b->id,
        member_id  => 'mogemoge',
        count      => 11,
    });

    is_deeply $ret->get_columns, {
        id         => 1,
        book_id    => $b->id,
        member_id  => 'mogemoge',
        count      => 11,
        comment    => undef,
        created_at => 1234567899,
        updated_at => 1234567899,
    }, 'data ok';

    record_count_ok $m, { circle_order => 1 };
    test_actionlog_ok $m, {
        id          => 1,
        member_id   => 'mogemoge',
        circle_id   => $c->id,
        message_id  => '本の発注を追加しました。: [ComicMarket999] circle / author (id=2, member_id=mogemoge, count=11)',
        parameters  => '["本の発注を追加しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","id","2","member_id","mogemoge","count","11"]',
    };
} 1234567899;
 
subtest "updating exist order ok" => sub_at {
    plan tests => 4;
    my $ret = $m->run_command('circle_order.update', {
        book_id    => $b->id,
        member_id  => 'mogemoge',
        count      => 2525,
    });

    is_deeply $ret->get_columns, {
        id         => 1,
        book_id    => $b->id,
        member_id  => 'mogemoge',
        count      => 2525,
        comment    => undef,
        created_at => 1234567899,
        updated_at => 1234567888,
    }, 'data ok';

    record_count_ok $m, { circle_order => 1 };
    test_actionlog_ok $m, {
        id          => 1,
        member_id   => 'mogemoge',
        circle_id   => $c->id,
        message_id  => '本の発注を変更しました。: [ComicMarket999] circle / author (id=2, member_id=mogemoge, before=11, after=2525, ret=1)',
        parameters  => '["本の発注を変更しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","id","2","member_id","mogemoge","before","11","after","2525","ret","1"]',
    };
} 1234567888;

subtest "deleting exist order ok" => sub_at {
    plan tests => 3;
    my $ret = $m->run_command('circle_order.update', {
        book_id    => $b->id,
        member_id  => 'mogemoge',
        count      => 0,
    });

    record_count_ok $m, { circle_order => 0 };
    test_actionlog_ok $m, {
        id          => 1,
        member_id   => 'mogemoge',
        circle_id   => $c->id,
        message_id  => '本の発注を削除しました。: [ComicMarket999] circle / author (id=2, member_id=mogemoge, deleted=1)',
        parameters  => '["本の発注を削除しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","id","2","member_id","mogemoge","deleted","1"]',
    };
} 1234567888;
