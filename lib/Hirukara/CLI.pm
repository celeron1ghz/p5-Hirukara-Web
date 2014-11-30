package Hirukara::CLI;
use strict;
use Class::Load;
use Hirukara::Database;

my %ALLOW_COMMAND = (
    circle => 'Hirukara::Model::Circle',
);

sub run {
    my $clazz = shift;
    my $type = shift;
    my $class = $ALLOW_COMMAND{$type} or die "No such command: '$type'";
    Class::Load::load_class($class);

    my $conf = do 'config/development.pl';
    my $database = Hirukara::Database->load($conf->{Teng});
    my $obj = $class->new_with_options(database => $database);
    $obj;
}

1;
