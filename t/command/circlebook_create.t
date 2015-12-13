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
    plan tests => 1;
    throws_ok {
        $m->run_command('circle_book.create', {
            circle_id => 'mogemoge',
            created_by => 'mogemoge',
        });
    } 'Hirukara::Circle::CircleNotFoundException';
};

subtest "creating circle book ok with default value" => sub_at {
    my $r = $m->run_command('circle_book.create', {
        circle_id => $c1->id,
        created_by => 'mogemoge',
    });

    is_deeply $r->get_columns, {
        id         => 1,
        circle_id  => $c1->id,
        book_name  => '新刊1冊ずつ',
        comment    => undef,
        created_at => 1234567890,
        created_by => 'mogemoge',
    }, 'data ok';

    test_actionlog_ok $m, {
        id => 1,
        member_id => 'mogemoge',
        circle_id => $c1->id,
        message_id => 'サークルに本を追加しました。: [ComicMarket999] circle / author (book_name=新刊1冊ずつ, comment=, member_id=mogemoge)',
        parameters => '["サークルに本を追加しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","book_name","新刊1冊ずつ","comment",null,"member_id","mogemoge"]',
    };
} 1234567890;

subtest "creating circle book ok optional params specified" => sub_at {
    my $r = $m->run_command('circle_book.create', {
        circle_id  => $c1->id,
        book_name  => 'book name!!!!!',
        comment    => 'comment!!!',
        created_by => 'mogemoge',
    });

    is_deeply $r->get_columns, {
        id         => 2,
        circle_id  => $c1->id,
        book_name  => 'book name!!!!!',
        comment    => 'comment!!!',
        created_at => 1234567891,
        created_by => 'mogemoge',
    }, 'data ok';

    test_actionlog_ok $m, {
        id => 1,
        member_id => 'mogemoge',
        circle_id => $c1->id,
        message_id => 'サークルに本を追加しました。: [ComicMarket999] circle / author (book_name=book name!!!!!, comment=comment!!!, member_id=mogemoge)',
        parameters => '["サークルに本を追加しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","book_name","book name!!!!!","comment","comment!!!","member_id","mogemoge"]',
    };
} 1234567891;
