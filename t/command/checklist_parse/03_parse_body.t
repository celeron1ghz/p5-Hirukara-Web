use utf8;
use strict;
use Test::More tests => 2;
use Test::Exception;
use Hirukara::Parser::CSV;
use t::Util;

subtest "Hirukara::Parser::CSV object value ok" => sub {
    my $r1 = test_reading_csv(<<EOT);
Header,a,comiketno,utf8,source
Circle,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
EOT

    is $r1->comiket_no, "comiketno", "comiketno ok";
    is $r1->source, "source", "source ok";
    isa_ok $r1->encoding, "Encode::utf8";
    is scalar @{$r1->circles}, 1, "circle count ok";

    my $data = {
        'type',         => "Circle",# 01
        'serial_no',    => 2,# 02
        'color',        => 3,# 03
        'page_no',      => 4,# 04
        'cut_index',    => 5,# 05
        'day',          => 6,# 06
        'area',         => 7,# 07
        'circle_sym',   => "８",# 08
        'circle_num',   => "09",# 09
        'genre',        => 10,# 10
        'circle_name',  => 11,# 11
        'circle_kana',  => 12,# 12
        'circle_author',=> 13,# 13
        'publish_info', => 14,# 14
        'url',          => 15,# 15
        'mail',         => 16,# 16
        'remark',       => 17,# 17
        'comment',      => 18,# 18
        'map_x',        => 19,# 19
        'map_y',        => 20,# 20
        'map_layout',   => 21,# 21
        'circle_flag',  => 22,# 22
        'update_info',  => 23,# 23
        'circlems',     => 24,# 24
        'rss',          => 25,# 25
        'rss_info',     => 26,# 26
    };

    is_deeply $r1->circles->[0], $data, "parse result ok";

    my $r2 = Hirukara::Parser::CSV::Row->new($data);
    is $r2->as_csv_column, "Circle,2,3,4,5,6,7,８,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26", "serialize ok";
};

subtest "multiline csv ok" => sub {
    my $r3 = test_reading_csv(<<EOT);
Header,a,comiketno,utf8,source
Circle,2,3,4,5,6,7,A,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
Circle,2,3,4,5,6,7,Ａ,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
EOT

    is scalar @{$r3->circles}, 2, "circle count ok";

    my $c1 = $r3->circles->[0];
    my $c2 = $r3->circles->[1];
    is $c1->circle_num, "09", "zero padding circle num";
    is $c2->circle_num, "09", "zero padding circle num";

    is $c1->circle_sym, "Ａ", "zero padding circle num";
    is $c2->circle_sym, "Ａ", "zero padding circle num";
};
