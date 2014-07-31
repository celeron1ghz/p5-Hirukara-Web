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

my %HOLE_LOOKUP = (
    "東1" => [ "Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ", "Ｆ", "Ｇ", "Ｈ", "Ｉ", "Ｊ", "Ｋ", "Ｌ" ],
    "東2" => [ "Ｍ", "Ｎ", "Ｏ", "Ｐ", "Ｑ", "Ｒ", "Ｓ", "Ｔ", "Ｕ", "Ｖ", "Ｗ", "Ｘ", "Ｙ", "Ｚ" ],
    "東3" => [ "ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", "サ" ],
    "東6" => [ "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ" ],
    "東5" => [ "ネ", "ノ", "ハ", "パ", "ヒ", "ピ", "フ", "プ", "ヘ", "ペ", "ホ", "ポ", "マ", "ミ" ],
    "東4" => [ "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "ル", "レ", "ロ" ],
    "西2" => [ "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ", "た", "ち", "つ", "て", "と", "な" ],
    "西1" => [ "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み", "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", ],
);

my %HOLE_OVERRIDE = (
    #"×" => "抽選漏れ",
    "Ａ" => __create_shutter_detect("東123", qw/4 5 6 15 16 17 44 45 60 61 72 73 74 83 84 85/),
    "シ" => "東456壁",
    "あ" => __create_shutter_detect("西2", qw/19 20 34 35 43 44 51 52/),
    "れ" => "西1壁",
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

