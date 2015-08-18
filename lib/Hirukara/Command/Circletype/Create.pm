package Hirukara::Command::Circletype::Create;
use Moose;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command';

has type_name => ( is => 'ro', isa => 'Str', required => 1 );
has scheme    => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;

    my $ret = $self->database->insert(circle_type => {
        type_name  => $self->type_name,
        scheme     => $self->scheme,
        created_at => time,
    });

    infof "CIRCLETYPE_CREATE: name=%s, scheme=%s", $self->type_name, $self->scheme;
    $ret;
}

1;
