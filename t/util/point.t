use strict;
use utf8;
use Hirukara::Constants::Area;
use Test::More tests => 13;
use Plack::Util;
use Hirukara::Database::Row::Circle;

my $POINT = Hirukara::Database::Row::Circle->can('circle_point');

sub test_lookup {
    my($sym,$num,$type,$result) = @_;

    my $obj = Plack::Util::inline_object(
        day         => sub { 1 },
        circle_sym  => sub { $sym },
        circle_num  => sub { $num },
        circle_type => sub { $type },
    );

    is $POINT->($obj), $result, "lookup ok";
}

test_lookup undef, undef, 1, 1;
test_lookup undef, undef, 2, 1;
test_lookup undef, undef, 3, 0;

test_lookup undef, undef, 0, 0;
test_lookup "Ａ",  undef, 0, 0;
test_lookup "Ａ",  3,     0, 10;
test_lookup "Ａ",  4,     0, 20;
test_lookup "Ｂ",  4,     0, 5;
test_lookup "Ｃ",  1,     0, 2;

test_lookup "Ａ",  3,     5, 20;
test_lookup "Ａ",  4,     5, 30;
test_lookup "Ｂ",  4,     5, 15;
test_lookup "Ｃ",  1,     5, 12;
