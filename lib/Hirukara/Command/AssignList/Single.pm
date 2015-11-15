package Hirukara::Command::AssignList::Single;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret  = $self->db->single(assign_list => { id => $self->id });
    $ret;
}

1;
