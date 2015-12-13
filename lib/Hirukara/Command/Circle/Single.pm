package Hirukara::Command::Circle::Single;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret = $self->db->single(circle => { id => $self->circle_id }, { prefetch => ['circle_books'] }) or return;
    $ret;
}

1;
