package Hirukara::Command::Circletype::Search;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

sub run {
    my $self = shift;
    [ $self->database->search('circle_type')->all ];
}

1;
