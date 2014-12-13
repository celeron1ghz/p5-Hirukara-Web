package Hirukara::Command::Actionlog::Create;
use Mouse;
use Carp();
use JSON();
use Hirukara::Actionlog;

with 'MouseX::Getopt', 'Hirukara::Command';

## TODO: not extending attr 'database' from role 'Hirukara::Command'
has database   => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );

has message_id => ( is => 'ro', isa => 'Str', required => 1 );
has circle_id  => ( is => 'ro', isa => 'Str' );
has parameters => ( is => 'ro', isa => 'HashRef', required => 1 );

sub run {
    my $self = shift;
    my $message_id = $self->message_id;
    my $mess  = Hirukara::Actionlog->get($message_id) or Carp::croak "actionlog message=$message_id not found";
    my $param = $self->parameters;
    my @keys  = $mess->{message} =~ /\$(\w+)/g;

    for my $k (@keys)   {
        defined $param->{$k} or Carp::croak "$message_id: key '$k' is not exist in args 'parameter'";
    }

    $self->database->insert(action_log => {
        message_id => $message_id,
        circle_id  => $self->circle_id,
        parameters => JSON::encode_json $param,
    });
}

1;
