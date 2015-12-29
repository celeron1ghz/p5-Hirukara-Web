use utf8;
use strict;
use t::Util;
use Test::More tests => 12;

my $m = create_mock_object;

## ComicMarket999 (default value)
my $c1 = create_mock_circle $m;
my $c2 = create_mock_circle $m, circle_name => 'circle2';
my $c3 = create_mock_circle $m, circle_name => 'circle3';

## ComicMarket777 (optional data)
my $c4 = create_mock_circle $m, circle_name => 'circle4', comiket_no => 'ComicMarket777';


## creating order
$m->run_command('circle_order.update' => { book_id =>  $c1->circle_books->[0]->id, count => 1, member_id => 'moge' });
$m->run_command('circle_order.update' => { book_id =>  $c2->circle_books->[0]->id, count => 2, member_id => 'fuga' });
$m->run_command('circle_order.update' => { book_id =>  $c3->circle_books->[0]->id, count => 3, member_id => 'piyo' });
$m->run_command('circle_order.update' => { book_id =>  $c4->circle_books->[0]->id, count => 4, member_id => 'piyo' });

is_deeply $m->db->get_total_price('ComicMarket999', 'moge')->get_columns, { count => 1, price => 500  }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket999', 'fuga')->get_columns, { count => 2, price => 1000 }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket999', 'piyo')->get_columns, { count => 3, price => 1500 }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket777', 'piyo')->get_columns, { count => 4, price => 2000 }, 'data ok';


## changing book price
$m->run_command('circle_book.update' => { circle_id => $c1->id, book_id => $c1->circle_books->[0]->id, book_name => "1", price => 100, run_by => 'moge' });
$m->run_command('circle_book.update' => { circle_id => $c2->id, book_id => $c2->circle_books->[0]->id, book_name => "2", price => 200, run_by => 'fuga' });
$m->run_command('circle_book.update' => { circle_id => $c3->id, book_id => $c3->circle_books->[0]->id, book_name => "3", price => 300, run_by => 'piyo' });
$m->run_command('circle_book.update' => { circle_id => $c4->id, book_id => $c4->circle_books->[0]->id, book_name => "4", price => 400, run_by => 'piyo' });

is_deeply $m->db->get_total_price('ComicMarket999', 'moge')->get_columns, { count => 1, price => 100 }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket999', 'fuga')->get_columns, { count => 2, price => 400 }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket999', 'piyo')->get_columns, { count => 3, price => 900 }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket777', 'piyo')->get_columns, { count => 4, price => 1600 }, 'data ok';


## partly delete
$m->run_command('circle_order.update' => { book_id =>  $c1->circle_books->[0]->id, count => 0, member_id => 'moge' });
$m->run_command('circle_order.update' => { book_id =>  $c2->circle_books->[0]->id, count => 0, member_id => 'fuga' });

is_deeply $m->db->get_total_price('ComicMarket999', 'moge')->get_columns, { count => undef, price => undef }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket999', 'fuga')->get_columns, { count => undef, price => undef }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket999', 'piyo')->get_columns, { count => 3, price => 900 }, 'data ok';
is_deeply $m->db->get_total_price('ComicMarket777', 'piyo')->get_columns, { count => 4, price => 1600 }, 'data ok';
