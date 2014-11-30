package Hirukara::CLI;
use strict;
use Class::Load;

my %ALLOW_COMMAND = (
    circle => 'Hirukara::Model::Circle',
);

sub run {
    my $clazz = shift;
    my $type = shift;
    my $class = $ALLOW_COMMAND{$type} or die "No such command: '$type'";
    Class::Load::load_class($class);

    my $obj = $class->new_with_options;
}

1;
