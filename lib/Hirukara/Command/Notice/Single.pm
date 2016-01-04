package Hirukara::Command::Notice::Single;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has key => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    [ $self->db->search('notice' => {
        key => $self->key,
    }, {
        order_by => "created_at DESC",
    })->all ];
}

__PACKAGE__->meta->make_immutable;
