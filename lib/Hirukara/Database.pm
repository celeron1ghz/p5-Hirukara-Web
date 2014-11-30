package Hirukara::Database;
use strict;
use parent 'Teng';
use Teng::Schema::Loader;
use Hirukara::Util;

sub load    {
    my($clazz,$conf) = @_;
    my $db = Teng::Schema::Loader->load(connect_info => $conf->{connect_info}, namespace => 'Hirukara::Database');
    $db->load_plugin("SearchJoined");
    $db->load_plugin("Count");

    *Hirukara::Database::Row::Circle::get_circle_point = Hirukara::Util->can("get_circle_point");
    $db;
}

1;
