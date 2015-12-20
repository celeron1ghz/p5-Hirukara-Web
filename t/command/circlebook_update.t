use utf8;
use strict;
use t::Util;
use Test::More tests => 2;
use Test::Time::At;
use Test::Exception;

my $m = create_mock_object;
my $c = create_mock_circle $m;
my $b = do_at { $m->run_command('circle_book.create', { circle_id => $c->id, created_by => 'mogemoge' }) } 1234567890;
delete_cached_log $m;

subtest "error on not exist circle" => sub {
    plan tests => 3;
    throws_ok {
        $m->run_command('circle_book.update', {
            circle_id  => '111',
            book_id    => '111',
            book_name  => 'moge',
            price      => '100',
            updated_by => 'piyo',
        });
    } 'Hirukara::Circle::CircleNotFoundException';

    throws_ok {
        $m->run_command('circle_book.update', {
            circle_id  => $c->id,
            book_id    => '111',
            book_name  => 'moge',
            price      => '100',
            updated_by => 'piyo',
        });
    } 'Hirukara::Circle::CircleNotFoundException';

    throws_ok {
        $m->run_command('circle_book.update', {
            circle_id  => '111',
            book_id    => $b->id,
            book_name  => 'moge',
            price      => '100',
            updated_by => 'piyo',
        });
    } 'Hirukara::Circle::CircleNotFoundException';
};

subtest "update ok" => sub {
    plan tests => 3;
    my $ret = $m->run_command('circle_book.update', {
        circle_id  => $c->id,
        book_id    => $b->id,
        book_name  => 'moge',
        price      => '100',
        updated_by => 'piyo',
    });

    is_deeply $ret->get_columns, {
        id        => $b->id,
        circle_id => $c->id,
        book_name => 'moge',
        comment   => undef,
        price     => 100,
        created_by => 'mogemoge',
        created_at => 1234567890,
    }, 'data ok';

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $c->id,
        member_id  => 'piyo',
        message_id => 'サークルの本の情報を更新しました。: [ComicMarket999] circle / author (id=2, book_name=moge, price=100, member_id=piyo)',
        parameters => '["サークルの本の情報を更新しました。","circle_id","3d2024b61ead1b0e391da4753ae77a23","id","2","book_name","moge","price","100","member_id","piyo"]',
    },
};
