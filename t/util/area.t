use strict;
use utf8;
use Hirukara::Constants::Area;
use Test::More tests => 4;
use Plack::Util;

sub test_lookup {
    my($sym,$num,$result) = @_;
    my $obj = Plack::Util::inline_object(circle_sym => sub { $sym }, circle_num => sub { $num });
    is Hirukara::Constants::Area::lookup($obj), $result, "lookup ok";
}

test_lookup undef, undef, undef;
test_lookup "Ａ",  undef, undef;
test_lookup "Ａ",  3,     "東123壁";
test_lookup "Ａ",  4,     "東123シャッター";
