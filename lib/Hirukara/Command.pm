package Hirukara::Command;
use Moose::Role;

has database => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );

requires 'run';

1;
