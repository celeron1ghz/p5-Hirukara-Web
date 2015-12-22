use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Test::Time::At;
use Test::Exception;

my $m = create_mock_object;
my $c1 = create_mock_circle $m;
delete_cached_log $m;

subtest "error on not exist circle" => sub {
    plan tests => 2;
    exception_ok {
        $m->run_command('circle_book.create', {
            circle_id => 'mogemoge',
            created_by => 'fugafuga',
        });
    } 'Hirukara::DB::NoSuchRecordException',
        ,qr/データが存在しません。\(table=circle, id=mogemoge, mid=fugafuga\)/;
};

subtest "creating circle book ok with default value" => sub_at {
    plan tests => 4;
    my $r = $m->run_command('circle_book.create', {
        circle_id => $c1->id,
        created_by => 'mogemoge',
    });

    is_deeply $r->get_columns, {
        id         => 2,
        circle_id  => $c1->id,
        book_name  => '新刊セット',
        price      => 500,
        comment    => undef,
        created_at => 1234567890,
        created_by => 'mogemoge',
    }, 'data ok';

    record_count_ok $m, { circle => 1, circle_book => 2 };
    test_actionlog_ok $m, {
        id => 1,
        member_id => 'mogemoge',
        circle_id => $c1->id,
        message_id => '本を追加しました。: [ComicMarket999] circle / author (id=2, book_name=新刊セット, comment=, member_id=mogemoge)',
        parameters => '["本を追加しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","id","2","book_name","新刊セット","comment",null,"member_id","mogemoge"]',
    };
} 1234567890;

subtest "creating circle book ok optional params specified" => sub_at {
    plan tests => 4;
    my $r = $m->run_command('circle_book.create', {
        circle_id  => $c1->id,
        book_name  => 'book name!!!!!',
        price      => 123,
        comment    => 'comment!!!',
        created_by => 'mogemoge',
    });

    is_deeply $r->get_columns, {
        id         => 3,
        circle_id  => $c1->id,
        book_name  => 'book name!!!!!',
        price      => 123,
        comment    => 'comment!!!',
        created_at => 1234567891,
        created_by => 'mogemoge',
    }, 'data ok';

    record_count_ok $m, { circle => 1, circle_book => 3 };
    test_actionlog_ok $m, {
        id => 1,
        member_id => 'mogemoge',
        circle_id => $c1->id,
        message_id => '本を追加しました。: [ComicMarket999] circle / author (id=3, book_name=book name!!!!!, comment=comment!!!, member_id=mogemoge)',
        parameters => '["本を追加しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","id","3","book_name","book name!!!!!","comment","comment!!!","member_id","mogemoge"]',
    };
} 1234567891;
