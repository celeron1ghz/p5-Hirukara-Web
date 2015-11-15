package Hirukara::Command::Circle::Single;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret = $self->db->single(circle => { id => $self->circle_id }) or return;
    $ret->circle_types($self->db->single(circle_type => { id => $ret->circle_type }));
    $ret;
}

1;
