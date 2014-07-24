use strict;
use utf8;
use Hirukara::AreaLookup;
use Test::More tests => 2;;
use Plack::Util;

sub test_lookup {
    my($sym,$num,$result) = @_;
    my $obj = Plack::Util::inline_object(circle_sym => sub { $sym }, circle_num => sub { $num });
    is Hirukara::AreaLookup::lookup($obj), $result, "lookup ok";
}

test_lookup undef, undef, undef;
test_lookup "Ａ",  undef, undef;
test_lookup "Ａ",  3,     "東123壁";
test_lookup "Ａ",  4,     "東123シャッター";
