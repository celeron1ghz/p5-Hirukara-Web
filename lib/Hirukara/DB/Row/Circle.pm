package Hirukara::DB::Row::Circle;
use utf8;
use strict;
use warnings;
use parent 'Teng::Row';
use Hirukara::Constants::Area;

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/circle_types checklists assigns/],
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

my %CACHED;

sub __cached    {
    my($c,$key) = @_;
    return unless $key;
    if (exists $CACHED{$key})   {
        return $CACHED{$key};
    } else {
        my $col = $c->handle->single(circle_type => { type_name => $key });
        $CACHED{$key} = $col ? $col->id : -1;
    }
}

sub recalc_circle_point {
    my($c) = @_; 
    my $circle_type = $c->circle_type || '';
    my $score;
    my $area = Hirukara::Constants::Area::lookup($c);
    $c->area($area);

    for ($area)   {   
        /偽壁/        and do { $score = 5;  last };
        /壁/          and do { $score = 10; last };
        /シャッター/  and do { $score = 20; last };

        $score = 2;
    }   

    for ($circle_type)  {
        $circle_type eq $c->__cached('ご配慮') and do { $score = 1; last };
        $circle_type eq $c->__cached('身内')   and do { $score = 1; last };
    }

    $score += 10 if $circle_type eq $c->__cached('ﾇﾇﾝﾇ');

    $c->circle_point($score);
    $c->update;

    return $score;
}

1;
