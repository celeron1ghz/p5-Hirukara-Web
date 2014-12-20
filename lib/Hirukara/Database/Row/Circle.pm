package Hirukara::Database::Row::Circle;
use strict;
use warnings;
use parent 'Teng::Row';

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/checklists assigns/],
);

1;
