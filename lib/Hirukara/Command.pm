package Hirukara::Command;
use Mouse::Role;
use Hirukara::CLI;
use Log::Minimal();

has database => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );

requires 'run';

my $LOG_MINIMAL_FUNC = sub {
    my($time, $type, $message, $trace, $raw_message) = @_;

    my($class,$path,$line) = caller(3);
    my $cmd = uc Hirukara::CLI::to_command_name($class);

    warn "$time [$type] $cmd: $message at $path line $line\n";
};

sub action_log  {
    my $self = shift;
    my $args = shift;
    my @logs;

    while ( my($key,$val) = splice @$args, 0, 2 )   {
        push @logs, "$key=$val";
    }

    local $Log::Minimal::PRINT = $LOG_MINIMAL_FUNC;
    Log::Minimal::infof join ", " => @logs;
}

1;
