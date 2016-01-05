package Hirukara::Command::Login;
use Moose::Role;

has id                      => ( is => 'ro', isa => 'Str', required => 1 );
has name                    => ( is => 'ro', isa => 'Str', required => 1 );
has screen_name             => ( is => 'ro', isa => 'Str', required => 1 );
has profile_image_url_https => ( is => 'ro', isa => 'Str', required => 1 );

1;
