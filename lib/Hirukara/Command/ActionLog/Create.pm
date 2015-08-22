package Hirukara::Command::ActionLog::Create;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

## TODO: not extending attr 'database' from role 'Hirukara::Command'
has database   => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );

has message_id => ( is => 'ro', isa => 'Str', required => 1 );
has circle_id  => ( is => 'ro', isa => 'Str' );
has parameters => ( is => 'ro', isa => 'HashRef', required => 1 );

sub run {
    my $self = shift;
    my $message_id = $self->message_id;
    my $param = $self->parameters;

    $self->database->insert(action_log => {
        message_id => $message_id,
        circle_id  => $self->circle_id,
        parameters => JSON::encode_json $param,
    });
}

1;
