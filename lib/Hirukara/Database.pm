package Hirukara::Database;
use strict;
use Teng::Schema::Loader;

sub load    {
    my($clazz,$conf) = @_;
    my $db = Teng::Schema::Loader->load(connect_info => $conf->{connect_info});
    $db->load_plugin("SearchJoined");
    $db;
}

1;
