package Hirukara::Command::Checklist::Search;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has where => ( is => 'ro', isa => 'HashRef', required => 1 );

sub run {
    my $self = shift;
    my $where = $self->where;
    my $ret = $self->database->search(checklist => $where); 
    $ret;
}

1;
