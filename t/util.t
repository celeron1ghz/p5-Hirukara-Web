use strict;
use utf8;
use Test::More tests => 2;
use Hirukara::Util;
use Mouse;
{
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

    is Hirukara::Util::get_circle_hash($obj), "c90577f24a48ba33cfe4c6fe967ad147", "circle hash ok";
}
{
    our %data2 = (
        "comiket_no"    => "ああ",
        "day"           => "いい",
        "circle_sym"    => "うう",
        "circle_num"    => "ええ",
        "circle_flag"   => "おお",
        "circle_name"   => "かか",
        "circle_author" => "きき",
    );

    my $obj = do {
        package Moge::Fuga;
        use strict;
        use Mouse;
        has $_ => ( is => 'ro', isa => 'Str' ) for keys %main::data2;
        __PACKAGE__->new(%main::data2);
    };

    is Hirukara::Util::get_circle_hash($obj), "92fe64da38542263faa093a05d217764", "circle hash ok";
}
{
    our %data3 = (
        "comiket_no"    => "ああ",
        "day"           => "いい",
        "area"          => "かか",
        "circle_sym"    => "うう",
        "circle_num"    => "ええ",
        "circle_flag"   => "おお",
    );

    my $obj = do {
        package Moge::Fuga::Piyo;
        use strict;
        use Mouse;
        has $_ => ( is => 'ro', isa => 'Str' ) for keys %main::data3;
        __PACKAGE__->new(%main::data3);
    };

    is Hirukara::Util::get_circle_space($obj), "ああ いい曜日 かかううええおお", "circle space ok";
}

