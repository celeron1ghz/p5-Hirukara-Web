package Hirukara::Database::Row::Member;
use utf8;
use strict;
use warnings;
use parent 'Teng::Row';

sub member_name_label   {
    my $self = shift;
    sprintf "%s (%s)", $self->member_name, $self->member_id;
}

1;
