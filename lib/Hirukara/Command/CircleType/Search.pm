package Hirukara::Command::CircleType::Search;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

sub run {
    my $self = shift;
    [ $self->db->search('circle_type')->all ];
}

1;
