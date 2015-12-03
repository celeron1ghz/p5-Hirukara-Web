package Hirukara::Database;
use 5.014002;
use Mouse v2.4.5;
extends qw/Aniki/;

__PACKAGE__->setup(
    schema => 'Hirukara::Database::Schema',
    filter => 'Hirukara::Database::Filter',
    result => 'Hirukara::Database::Result',
    row    => 'Hirukara::Database::Row',
);

__PACKAGE__->meta->make_immutable();

