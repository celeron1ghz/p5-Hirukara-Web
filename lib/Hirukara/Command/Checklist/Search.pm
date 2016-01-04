package Hirukara::Command::Checklist::Search;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has where => ( is => 'ro', isa => 'HashRef', required => 1 );

sub run {
    my $self  = shift;
    my $where = $self->where;
    my $ret   = $self->db->select_joined(checklist => [
        member => [ LEFT => { 'member.member_id' => 'checklist.member_id' } ]
    ], $where, {}); 
    $ret;
}

__PACKAGE__->meta->make_immutable;
