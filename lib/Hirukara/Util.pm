package Hirukara::Util;
use strict;
use utf8;
use Digest::MD5 'md5_hex';
use Encode;

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

    sprintf "%s %s曜日 %s%s%02d%s", map { $c->$_ }
          "comiket_no"
        , "day"
        , "area"
        , "circle_sym"
        , "circle_num"
        , "circle_flag"
}

1;
