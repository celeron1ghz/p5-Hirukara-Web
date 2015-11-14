package Hirukara::Command;
use Moose::Role;

has hirukara => ( is => 'ro', isa => 'Hirukara',           required => 1 );

sub db {
    my $self = shift;
    $self->hirukara->db;
}

sub actioninfo {
    my $self = shift;
    $self->hirukara->actioninfo(@_);
}

requires 'run';

1;
