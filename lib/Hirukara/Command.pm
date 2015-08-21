package Hirukara::Command;
use Moose::Role;

has database => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );
has logger   => ( is => 'ro', isa => 'Hirukara::Logger',   required => 1 );

requires 'run';

1;
