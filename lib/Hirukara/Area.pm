package Hirukara::Area;
use utf8;
use Moose;

has sym2area     => ( is => 'ro', isa => 'HashRef', default => sub { +{} } );
has area2sym     => ( is => 'ro', isa => 'HashRef', default => sub { +{} } );
has sym_resolver => ( is => 'ro', isa => 'HashRef', default => sub { +{} } );

sub between {
    my($on_true,$on_false,$from,$to) = @_;
    $from > $to and die "$from > $to";

    sub {
        my $circle = shift;
        my $val = $circle->circle_num;
        return $from <= $val && $val <= $to ? $on_true : $on_false;
    }
}

sub in_list {
    my $on_true = shift;
    my $on_false = shift;
    my %map = map { $_ => 1 } @_;
    sub {
        my $circle = shift;
        my $val = $circle->circle_num;
        $map{$val} ? $on_true : $on_false;
    }
}

my $east_shutter   = in_list('シャッター',  '壁',  4,5,6,15,16,17,28,29,44,45,46,61,62,73,74,75,84,85,86);
my $east_nisekabe  = between('偽壁',        '',    1,48);
my $east_shimanaka = in_list('誕生日席',    '',    1,7,8,15,16,23,24,30,31,37,38,45,46,53,54,60);

my $west_shutter   = in_list('シャッター',  '壁',  19,20,34,35,43,44,51,52);
my $west_shimanaka = sub { '' };

my $hole_b = sub { my $c = shift; $c->day eq 1 ? in_list('偽壁', '' => 1..27,39,40,52)->($c) : '' };
my $hole_c = sub { my $c = shift; $c->day ne 1 ? in_list('偽壁', '' => 1..31,45,46,60)->($c) : $east_shimanaka->($c) };

my $edge_of_hole = sub { my $c = shift; $c->day ne 3 ? in_list('偽壁', '' => 1,13,14,26..52)->($c) : '' };
my $side_of_edge = sub { my $c = shift; $c->day eq 3 ? in_list('偽壁', '' => 1,15,16,30..60)->($c) : $east_shimanaka->($c) };

sub BUILD {
    my $self = shift;
    my $hole_mapping     = $self->hole_mapping;
    my $particular_areas = $self->particular_areas;

    while(my($area,$holes) = each %$hole_mapping)    {
        for my $hole (@$holes)  {
            $self->area2sym->{$area} = $hole;
            $self->sym2area->{$hole} = $area;
            $self->sym_resolver->{$hole} = $area =~ /東/ ? $east_shimanaka : $west_shimanaka;
        }
    }

    while(my($hole,$resolver) = each %$particular_areas)    {
        $self->sym_resolver->{$hole} = $resolver;
    }
}

sub hole_mapping {
    {
        "東1" => [ "Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ", "Ｆ", "Ｇ", "Ｈ", "Ｉ", "Ｊ", "Ｋ", "Ｌ" ],
        "東2" => [ "Ｍ", "Ｎ", "Ｏ", "Ｐ", "Ｑ", "Ｒ", "Ｓ", "Ｔ", "Ｕ", "Ｖ", "Ｗ", "Ｘ", "Ｙ", "Ｚ" ],
        "東3" => [ "ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", "サ" ],
        "東6" => [ "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ" ],
        "東5" => [ "ネ", "ノ", "ハ", "パ", "ヒ", "ピ", "フ", "プ", "ヘ", "ペ", "ホ", "ポ", "マ", "ミ" ],
        "東4" => [ "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "ル", "レ", "ロ" ],
        "西2" => [ "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ", "た", "ち", "つ", "て", "と", "な" ],
        "西1" => [ "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み", "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", ],
    }
}

sub particular_areas    {
    {
        'Ａ' => $east_shutter,
        'Ｂ' => $hole_b,
        'Ｃ' => $hole_c,
        'Ｍ' => $east_nisekabe,
        'Ｎ' => $east_nisekabe,
        'Ｙ' => $east_nisekabe,
        'Ｚ' => $east_nisekabe,
        'サ' => $edge_of_hole,
        'コ' => $side_of_edge,
        'シ' => $east_shutter,
        'ス' => $edge_of_hole,
        'セ' => $side_of_edge,
        'ネ' => $east_nisekabe,
        'ノ' => $east_nisekabe,
        'マ' => $east_nisekabe,
        'ミ' => $east_nisekabe,
        'ロ' => $edge_of_hole,
        'レ' => $side_of_edge,
        'あ' => $west_shutter,
        'れ' => $west_shutter,
    }
}

sub get_area    {
    my($self,$circle) = @_;
    my $meth = $self->sym_resolver->{$circle->circle_sym} or return;
    my $hole = $self->sym2area->{$circle->circle_sym} or return;
    sprintf "%s%s", $hole, $meth->($circle);
}

__PACKAGE__->meta->make_immutable;
