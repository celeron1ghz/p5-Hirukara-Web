package Hirukara::Command::Actionlog::Select;
use Moose;
use Hirukara::Actionlog;

with 'MooseX::Getopt', 'Hirukara::Command';

has count => ( is => 'ro', isa => 'Int', default => 20 );

sub run {
    my $self = shift;
    my $cond = {};
    my $opts = { order_by => 'id DESC' };
    $opts->{limit} = $self->count if $self->count;

    {
        count      => $self->database->count('action_log'),
        actionlogs => [ map { Hirukara::Actionlog->extract_log($_) } $self->database->search(action_log => $cond, $opts) ],
    }
}

1;
