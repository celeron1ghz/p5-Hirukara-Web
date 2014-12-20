package Hirukara::Database::Row::AssignList;
use strict;
use warnings;
use parent 'Teng::Row';

use Class::Accessor::Lite (
    new => 0,
    rw => [qw/assign/]
);

1;
