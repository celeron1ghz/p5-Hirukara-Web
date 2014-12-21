package Hirukara::Util;
use strict;
use utf8;
use Hirukara::Constants::Area;

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

1;
