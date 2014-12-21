package Hirukara::Database;
use strict;
use parent 'Teng';
use Teng::Schema::Loader;

sub load    {
    my($clazz,$conf) = @_;
    my $db = Teng::Schema::Loader->load(connect_info => $conf->{connect_info}, namespace => 'Hirukara::Database');
    $db->load_plugin("SearchJoined");
    $db->load_plugin("Count");
    $db;
}

1;
