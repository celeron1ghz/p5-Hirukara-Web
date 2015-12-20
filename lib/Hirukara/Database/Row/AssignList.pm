package Hirukara::Database::Row::AssignList;
use utf8;
use 5.014002;
use Mouse v2.4.5;
extends qw/Hirukara::Database::Row/;

sub assign_list_label   {
    my $self = shift;
    my $name = $self->get_columns->{'member_name'} || $self->member_id || "未割当";
    sprintf "%s [%s]", $self->name, $name;
}

1;