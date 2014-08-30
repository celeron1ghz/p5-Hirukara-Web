package Hirukara::Util;
use strict;
use utf8;
use Digest::MD5 'md5_hex';
use Encode;
use Hirukara::Constants::Area;

sub get_circle_hash {
    my($c) = @_;
    my $val = join "-", map { encode_utf8 $c->$_ }
          "comiket_no"
        , "day"
        , "circle_sym"
        , "circle_num"
        , "circle_flag"
        , "circle_name"
        , "circle_author";

    return md5_hex($val);
}

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

    for ($type)   {
        /偽壁/        and return 5;
        /壁/          and return 10;
        /シャッター/  and return 20;
    }

    return 2;
}

sub get_assign_list_label   {
    my($a) = @_;
    sprintf "[%s] %s", ($a->member_id or "未割当"), $a->name;
} 

1;
