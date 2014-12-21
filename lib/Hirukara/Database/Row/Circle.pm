package Hirukara::Database::Row::Circle;
use utf8;
use strict;
use warnings;
use parent 'Teng::Row';

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

1;
