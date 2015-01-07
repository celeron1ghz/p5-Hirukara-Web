package Hirukara::Constants::Area;
use utf8;
use strict;
use warnings;

sub matched_number {
    my($area,$matched,$not_matched,@numbers) = @_;
    my %nums = map { $_ => 1 } @numbers;

    return sub {
        my($circle) = @_;
        my $num = $circle->circle_num or return;
        $nums{$num} ? "$area$matched" : "$area$not_matched";
    };
}

sub shutter {
    my($sym,@numbers) = @_;
    matched_number($sym, "シャッター", "壁", @numbers);
}

sub fake_wall   {
    my($sym,@numbers) = @_;
    matched_number($sym, "偽壁", "", @numbers);
}

sub conditional_fake_wall   {
    my($callback,$area,@numbers) = @_;
    my %nums = map { $_ => 1 } @numbers;

    return sub {
        my($circle) = @_;
        my $num = $circle->circle_num or return;
        local $_ = $circle;
        $callback->($circle) && $nums{$num} ? "${area}偽壁" : "$area";
    };
}


my %HOLE_LOOKUP = (
    "東1" => [ "Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ", "Ｆ", "Ｇ", "Ｈ", "Ｉ", "Ｊ", "Ｋ", "Ｌ" ],
    "東2" => [ "Ｍ", "Ｎ", "Ｏ", "Ｐ", "Ｑ", "Ｒ", "Ｓ", "Ｔ", "Ｕ", "Ｖ", "Ｗ", "Ｘ", "Ｙ", "Ｚ" ],
    "東3" => [ "ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", "サ" ],
    "東6" => [ "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ" ],
    "東5" => [ "ネ", "ノ", "ハ", "パ", "ヒ", "ピ", "フ", "プ", "ヘ", "ペ", "ホ", "ポ", "マ", "ミ" ],
    "東4" => [ "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "ル", "レ", "ロ" ],
    "西2" => [ "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ", "た", "ち", "つ", "て", "と", "な" ],
    "西1" => [ "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み", "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", ],
);

my %HOLE_OVERRIDE = (
    #"×" => "抽選漏れ",
    "Ａ" => shutter("東123" => qw/4 5 6 15 16 17 44 45 60 61 72 73 74 83 84 85/),
    "Ｂ" => conditional_fake_wall(sub{ $_->day eq "1" or $_->day eq "2" } => "東1", 1 .. 26),
    "Ｃ" => conditional_fake_wall(sub{ $_->day eq "3" }                   => "東1", 1 .. 30),
    "Ｍ" => fake_wall("東2" => 25 .. 48),
    "Ｎ" => fake_wall("東2" =>  1 .. 24),
    "Ｙ" => fake_wall("東2" => 25 .. 48),
    "Ｚ" => fake_wall("東2" =>  1 .. 24),
    "サ" => fake_wall("東3" => 27 .. 52),

    "シ" => shutter("東456" => qw/4 5 6 15 16 17 44 45 60 61 72 73 74 83 84 85/),
    "ス" => conditional_fake_wall(sub{ $_->day eq "1" }                   => "東6", 1 .. 26),
    "セ" => conditional_fake_wall(sub{ $_->day eq "2" or $_->day eq "3" } => "東6", 1 .. 30),

    "ネ" => fake_wall("東5" => 25 .. 48),
    "ノ" => fake_wall("東5" =>  1 .. 24),
    "マ" => fake_wall("東5" => 25 .. 48),
    "ミ" => fake_wall("東5" =>  1 .. 24),
    "ロ" => fake_wall("東5" => 27 .. 52),

    "あ" => shutter("西2" => qw/19 20 34 35 43 44 51 52/),
    "れ" => shutter("西1" => qw/19 20 34 35 43 44 51 52/),
);

my %AREAS = (
    "東123" => [ map { @$_ } map { $HOLE_LOOKUP{$_} } "東1", "東2", "東3" ],
    "東456" => [ map { @$_ } map { $HOLE_LOOKUP{$_} } "東4", "東5", "東6" ],
    "西12"  => [ map { @$_ } map { $HOLE_LOOKUP{$_} } "西1", "西2" ],
);

my %SYM_LOOKUP;

while (my($hole,$syms) = each %HOLE_LOOKUP) {
    for my $sym (@$syms) {
        $SYM_LOOKUP{$sym} = $hole;
    }
}

%SYM_LOOKUP = (%SYM_LOOKUP,%HOLE_OVERRIDE);

sub areas   {
    sort keys %AREAS;
}

sub get_syms_by_area {
    my($class,$key) = @_;
    $AREAS{$key};
}

sub lookup  {
    my $circle = shift;
    my $area = $circle->circle_sym;
    my $ret = $SYM_LOOKUP{$area};
    return $ret unless ref $ret;
    return $ret->($circle);
}

1;

