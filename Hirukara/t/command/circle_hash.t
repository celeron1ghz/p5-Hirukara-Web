use strict;
use utf8;
use Test::More tests => 4;
use Mouse;
use_ok 'Hirukara::Command::Circle::Create';

{
    package
        Hirukara::Test::Circle;
    use Mouse;

    has $_ => ( is => 'ro', isa => 'Str' )
    for "comiket_no",
        "day",
        "circle_sym",
        "circle_num",
        "circle_flag",
        "circle_name",
        "circle_author";
}

sub hash_equals {
    my $hashstr = shift;
    my $obj = Hirukara::Test::Circle->new(@_);
    is Hirukara::Command::Circle::Create::id($obj), $hashstr, "circle hash ok";
}

hash_equals("77ca48c9876d9e6c2abad3798b589664" => 
    "comiket_no"    => "aa",
    "day"           => "bb",
    "circle_sym"    => "cc",
    "circle_num"    => "dd",
    "circle_flag"   => "ee",
    "circle_name"   => "ff",
);

hash_equals("9dd2d061ce296d527c5d659979164aa8" => 
    "comiket_no"    => "ああ",
    "day"           => "いい",
    "circle_sym"    => "うう",
    "circle_num"    => "ええ",
    "circle_flag"   => "おお",
    "circle_name"   => "かか",
    "circle_author" => "きき",
);
 
hash_equals("2cdee922bbbfa69518d24422afd47531" => 
    "comiket_no"    => "ああ",
    "day"           => "いい",
    "area"          => "かか",
    "circle_sym"    => "うう",
    "circle_num"    => "5",
    "circle_flag"   => "おお",
);
