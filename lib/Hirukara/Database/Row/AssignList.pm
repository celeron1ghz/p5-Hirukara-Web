package Hirukara::Database::Row::AssignList;
use utf8;
use 5.014002;
use Mouse v2.4.5;
extends qw/Hirukara::Database::Row/;

sub assign_list_label   {
    my $self = shift;
    my $mem  = $self->member;
    my $name = $mem ? $mem->member_name : "未割当";
    sprintf "[%s %s日目] %s (%s)", $self->comiket_no, $self->day, $self->name, $name;
}

1;
