use utf8;
use strict;
use Test::More tests => 2;
use Hash::MultiValue;
use t::Util;

sub hash { Hash::MultiValue->new(@_) }

my $m = create_mock_object;

subtest "no condition test" => sub {
    plan tests => 3;
    my $r1 = $m->get_condition_object(hash());
    is        $r1->{condition}->as_sql => '`circle`.`comiket_no` = ?';
    is_deeply [$r1->{condition}->bind], ['ComicMarket999'];
    is        $r1->{condition_label} => 'なし';
};

subtest "have condition test" => sub {
    plan tests => 3;
    my $r2 = $m->get_condition_object(hash(day => 1));
    is        $r2->{condition}->as_sql => '((`day` = ?)) AND (`circle`.`comiket_no` = ?)';
    is_deeply [$r2->{condition}->bind], [1, 'ComicMarket999'];
    is        $r2->{condition_label} => '1日目';
};
