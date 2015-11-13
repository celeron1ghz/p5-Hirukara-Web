package Hirukara::Command;
use Moose::Role;

has hirukara => ( is => 'ro', isa => 'Hirukara',           required => 1 );
has database => ( is => 'ro', isa => 'Hirukara::DB',       required => 1 );
has logger   => ( is => 'ro', isa => 'Hirukara::Logger',   required => 1 );

requires 'run';

1;
