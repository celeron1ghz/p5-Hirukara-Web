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
    my $name = $self->get_columns->{'member_name'} || $self->member_id || "未割当";
    sprintf "%s [%s]", $self->name, $name;
}

1;
