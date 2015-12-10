package Hirukara::Database::Row::Member;
use utf8;
use 5.014002;
use Mouse v2.4.5;
extends qw/Hirukara::Database::Row/;

sub member_name_label   {
    my $self = shift;
    sprintf "%s (%s)", $self->member_name, $self->member_id;
}

1;
