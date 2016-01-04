package Hirukara::Command::Auth::Single;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str' );
has role_type => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $cond = {};
    $cond->{member_id} = $self->member_id;
    $cond->{role_type} = $self->role_type;
    $self->db->single(member_role => $cond);
}

__PACKAGE__->meta->make_immutable;
