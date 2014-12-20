package Hirukara::Database::Row::Checklist;
use strict;
use warnings;
use parent 'Teng::Row';

use Class::Accessor::Lite (
    new => 0,
    rw => [ qw/member/ ],
);

1;
