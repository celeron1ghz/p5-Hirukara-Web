use strict;
use Test::More tests => 1;
use Hirukara::Util;
use Mouse;

our %data = (
    "comiket_no"    => "aa",
    "day"           => "bb",
    "circle_sym"    => "cc",
    "circle_num"    => "dd",
    "circle_flag"   => "ee",
    "circle_name"   => "ff",
    "circle_author" => "gg",
);

my $obj = do {
    package Moge::Fuga;
    use strict;
    use Mouse;
    has $_ => ( is => 'ro', isa => 'Str' ) for keys %main::data;
    __PACKAGE__->new(%main::data);
};

is Hirukara::Util::get_circle_hash($obj), "c90577f24a48ba33cfe4c6fe967ad147";
