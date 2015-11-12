package Hirukara::Command::Checklist::Search;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has where => ( is => 'ro', isa => 'HashRef', required => 1 );

sub run {
    my $self = shift;
    my $where = $self->where;
    my $ret = $self->database->search_joined(checklist => [
        member => [ LEFT => { 'member.member_id' => 'checklist.member_id' } ]
    ], $where); 
    $ret;
}

1;
