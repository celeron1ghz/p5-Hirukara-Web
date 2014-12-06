package Hirukara::Export;
use Mouse::Role;
use File::Temp();

has file => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );

has checklists => ( is => 'rw', isa => 'ArrayRef' );

requires 'get_extension';

requires 'process';

1;
