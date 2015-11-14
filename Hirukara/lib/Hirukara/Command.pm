package Hirukara::Command;
use Moose::Role;

has hirukara => ( is => 'ro', isa => 'Hirukara',           required => 1 );

requires 'run';

1;
