package Hirukara::DB;
use strict;
use warnings;
use utf8;
use parent qw(Teng);
use Teng::Schema::Loader;

sub load    {
    my $class = shift;
    Teng::Schema::Loader->load(
        connect_info => [@_],
        namespace    => __PACKAGE__,
    );  
}

__PACKAGE__->load_plugin('Count');
__PACKAGE__->load_plugin('Replace');
__PACKAGE__->load_plugin('Pager');
__PACKAGE__->load_plugin('SearchJoined');

1;
