package Hirukara::Util;
use strict;
use utf8;
use Hirukara::Constants::Area;

sub get_circle_space {
    my($c) = @_;
    my $no = $c->comiket_no;
        $no =~ s/ComicMarket/C/;

    sprintf "%s %s日目 %s%02d%s", $no, map { $c->$_ }
          "day"
        , "circle_sym"
        , "circle_num"
        , "circle_flag"
}

sub get_circle_point    {
    my($c) = @_;
    return 1 if $c->circle_type eq 1; ## gohairyo
    return 1 if $c->circle_type eq 2; ## miuti

    my $type = Hirukara::Constants::Area::lookup($c) or return 0;
    my $score;

    for ($type)   {
        /偽壁/        and do { $score = 5;  last };
        /壁/          and do { $score = 10; last };
        /シャッター/  and do { $score = 20; last };

        $score = 2;
    }

    $score += 10 if $c->circle_type eq 5; ## malonu :-)

    return $score;
}

sub get_assign_list_label   {
    my($a) = @_;
    sprintf "%s [%s]", $a->name, ($a->member_id or "未割当");
} 

sub get_member_name_label   {
    my $m = shift;
    sprintf "%s (%s)", $m->member_name, $m->member_id;
}

1;
