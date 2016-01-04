package Hirukara::Command::CircleType::Search;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

sub run {
    my $self = shift;
    [ $self->db->search('circle_type')->all ];
}

__PACKAGE__->meta->make_immutable;
