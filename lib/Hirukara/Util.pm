package Hirukara::Util;
use strict;
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

1;
