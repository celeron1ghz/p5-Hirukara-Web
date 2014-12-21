package Hirukara::Database::Row::AssignList;
use utf8;
use strict;
use warnings;
use parent 'Teng::Row';

use Class::Accessor::Lite (
    new => 0,
    rw => [qw/assign member/]
);

sub assign_list_label   {
    my $self = shift;
    sprintf "%s [%s]", $self->name, ($self->member_id or "未割当");
}

1;
