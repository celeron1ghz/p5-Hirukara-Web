package Hirukara::Database::Row::AssignList;
use utf8;
use 5.014002;
use Mouse v2.4.5;
use Hirukara::Constants::Area;
extends qw/Hirukara::Database::Row/;

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
