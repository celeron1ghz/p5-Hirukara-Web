use utf8;
use strict;
use Hirukara::Area;
use Test::More tests => 1;
use Test::Exception;
use t::Util;

my $m = create_mock_object;
my $area = Hirukara::Area->new;

=for

subtest "between() test" => sub {
    plan tests => 11;
    throws_ok { Hirukara::AreaLookup::between(9,9,2,1) } qr/2 > 1 at/;

    my $m1 = Hirukara::AreaLookup::between(1,0, 1,1);
    is $m1->(-1), 0;
    is $m1->(0),  0;
    is $m1->(1),  1;
    is $m1->(2),  0;

    my $m2 = Hirukara::AreaLookup::between(1,0, 1,30);
    is $m2->(-1), 0;
    is $m2->(0),  0;
    is $m2->(1),  1;
    is $m2->(29), 1;
    is $m2->(30), 1;
    is $m2->(31), 0;
};

subtest "in_list() test" => sub {
    plan tests => 14;
    my $m1 = Hirukara::AreaLookup::in_list(1,0, 1,30);
    is $m1->('moge'), 0;
    is $m1->('fuga'), 0;
    is $m1->(1),      1;
    is $m1->('1'),    1;
    is $m1->(-1),     0;
    is $m1->('-1'),   0;

    my $m2 = Hirukara::AreaLookup::in_list(1,0, 1,4,6);
    is $m2->(0), 0;
    is $m2->(1), 1;
    is $m2->(2), 0;
    is $m2->(3), 0;
    is $m2->(4), 1;
    is $m2->(5), 0;
    is $m2->(6), 1;
    is $m2->(7), 0;
};

=cut

subtest "get_area() check" => sub {
    my $areas = [
        [ "Ａ", 01, => "東1壁" ],
        [ "Ａ", 04, => "東1シャッター" ],

        [ "Ｍ", 01, => "東2偽壁" ],
        [ "Ｍ", 48, => "東2偽壁" ],
        [ "Ｍ", 49, => "東2" ],

        [ "ア",  1, => "東3誕生日席" ],
        [ "ア",  2, => "東3" ],
        [ "ア",  7, => "東3誕生日席" ],
        [ "ア",  8, => "東3誕生日席" ],
        [ "ア",  9, => "東3" ],
    ];

    plan tests => scalar @$areas;
    my $cnt = 0;
    for my $a (@$areas) {
        my($sym,$num,$result) = @$a;
    
        my $args = {};
        $args->{circle_sym}  = $sym  if $sym;
        $args->{circle_num}  = $num  if $num;
    
        my $c = create_mock_circle $m, %$args, circle_name => "circle " . ++$cnt;
        is $area->get_area($c), $result, "result is $result";
    }
};
