package Hirukara::Database::Row::Circle;
use utf8;
use strict;
use warnings;
use parent 'Teng::Row';
use Hirukara::Constants::Area;

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/checklists assigns/],
);

sub circle_space {
    my($c) = @_; 
    my $no = $c->comiket_no;
        $no =~ s/ComicMarket/C/;

    sprintf "%s %s日目 %s%02d%s", $no, map { $c->$_ }
          "day"
        , "circle_sym"
        , "circle_num"
        , "circle_flag"
}

sub simple_circle_space {
    my($c) = @_; 

    sprintf "%s %s%02d%s", map { $c->$_ }
          "area"
        , "circle_sym"
        , "circle_num"
        , "circle_flag"
}

sub circle_point    {
    my($c) = @_; 
    my $circle_type = $c->circle_type || '';
    return 1 if $circle_type eq 1; ## gohairyo
    return 1 if $circle_type eq 2; ## miuti

    my $type = Hirukara::Constants::Area::lookup($c) or return 0;
    my $score;

    for ($type)   {   
        /偽壁/        and do { $score = 5;  last };
        /壁/          and do { $score = 10; last };
        /シャッター/  and do { $score = 20; last };

        $score = 2;
    }   

    $score += 10 if $circle_type eq 5; ## malonu :-)

    return $score;
}

1;
