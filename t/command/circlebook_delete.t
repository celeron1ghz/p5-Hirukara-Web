use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Test::Exception;

my $m = create_mock_object;
my $c = create_mock_circle $m;
my $r = $c->circle_books->[0];

subtest "deleting circle_book ok" => sub {
    delete_cached_log $m;
    record_count_ok $m, { circle_book => 1, circle_order => 0 };
};

subtest "cannot delete on order is exist" => sub {
    plan tests => 3;
    $m->run_command('circle_order.update', { book_id => $r->id, count => 1, member_id => 'mogemoge' });
    delete_cached_log $m;

    exception_ok {
        $m->run_command('circle_book.delete', {
            circle_id  => $c->id,
            book_id    => $r->id,
            member_id  => 'mogemoge',
        });
    } 'Hirukara::DB::CircleOrderRecordsStillExistsException',
        qr/^サークル 'circle' の本 '新刊セット' はまだ発注している人がいます。本の削除を行う際は全ての発注を削除してから行ってください。\(cid=3d2024b61ead1b0e391da4753ae77a23, bid=1\)/;

    record_count_ok $m, { circle_book => 1, circle_order => 1 };
};

subtest "circle_book delete ok" => sub {
    plan tests => 3;
    $m->run_command('circle_order.update', { book_id => $r->id, count => 0, member_id => 'mogemoge' });
    delete_cached_log $m;

    $m->run_command('circle_book.delete', {
        circle_id  => $c->id,
        book_id    => $r->id,
        member_id  => 'mogemoge',
    });

    record_count_ok $m, { circle_book => 0, circle_order => 0 };
    test_actionlog_ok $m, {
        id          => 1,
        circle_id   => $c->id,
        member_id   => 'mogemoge',,
        message_id  => '本を削除しました。: [ComicMarket999] circle / author (id=1, book_name=新刊セット, member_id=mogemoge)',
        parameters  => '["本を削除しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","id","1","book_name","新刊セット","member_id","mogemoge"]',
    };
};
