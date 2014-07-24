package Hirukara::AreaLookup;
use strict;
use utf8;

sub __create_shutter_detect   {
    my($area,@numbers) = @_;
    my %nums = map { $_ => 1 } @numbers;

    return sub {
        my($circle) = @_;
        my $num = $circle->circle_num or return;
        $nums{$num} ? "${area}シャッター" : "${area}壁";
    };
}

my %LOOKUP = (
    "Ａ" => __create_shutter_detect("東123", qw/4 5 6 15 16 17 44 45 60 61 72 73 74 83 84 85/),
    "シ" => "東456壁",
    "あ" => __create_shutter_detect("西1", qw/19 20 34 35 43 44 51 52/),
    "れ" => "西2壁",
);

sub lookup  {
    my $circle = shift;
    my $area = $circle->circle_sym;
    my $ret = $LOOKUP{$area};

    return $ret unless ref $ret;
    return $ret->($circle);
}

1;
