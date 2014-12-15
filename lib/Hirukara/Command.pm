package Hirukara::Command;
use Mouse::Role;
use Log::Minimal();
use Hirukara::CLI;
use Hirukara::Actionlog;
use Hirukara::Command::Actionlog::Create;
use Encode;

has database => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );

requires 'run';

my $LOG_MINIMAL_FUNC = sub {
    my($time, $type, $message, $trace, $raw_message) = @_;
    my($class,$path,$line) = caller(3);

    warn "$time [$type] $message at $path line $line\n";
};

sub action_log  {
    my $self = shift;
    my $args = shift;
    my($class) = caller;
    my @logs;
    my $cmd;

    if (defined $args && not ref $args) {
        $cmd = $args;
        $args = shift;
    } else {
        $cmd = uc Hirukara::CLI::to_command_name($class);
    }

    ## backup args
    my @args = @$args;

    while ( my($key,$val) = splice @$args, 0, 2 )   {
        push @logs, "$key=$val";
    }

    local $Log::Minimal::PRINT = $LOG_MINIMAL_FUNC;
    Log::Minimal::infof "%s: %s", $cmd, join ", " => @logs;

    if ( Hirukara::Actionlog->get($cmd) )   {
        Hirukara::Command::Actionlog::Create->new(
            database   => $self->database,
            message_id => $cmd,
            parameters => { @args },
        )->run;
    }
}

1;
