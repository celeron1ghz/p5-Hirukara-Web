package Hirukara::Command::Actionlog::Select;
use Mouse;
use Log::Minimal;
use Hirukara::Actionlog;

with 'MouseX::Getopt', 'Hirukara::Command';

has count => ( is => 'ro', isa => 'Int', default => 20 );

sub run {
    my $self = shift;
    my $cond = {};
    my $opts = { order_by => 'id DESC' };
    $opts->{limit} = $self->count if $self->count;

    [ map { Hirukara::Actionlog->extract_log($_) } $self->database->search(action_log => $cond, $opts) ];
}

1;
