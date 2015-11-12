package Hirukara::Command::ActionLog::Select;
use Moose;
use Data::Page;

with 'MooseX::Getopt', 'Hirukara::Command';

has page  => ( is => 'ro', isa => 'Int|Undef', default => 0 );
has count => ( is => 'ro', isa => 'Int', default => 30 );

sub run {
    my $self = shift;
    my $cond = {};
    my $opts = { order_by => 'id DESC' };

    my $count = $self->database->count('action_log');
    my $pager = Data::Page->new($count, $self->count, $self->page);

    $opts->{limit} = $self->count if $self->count;
    $opts->{offset} = $pager->skipped if $self->page;

    my @logs = $self->database->search(action_log => $cond, $opts);
    { actionlogs => \@logs, pager => $pager }
}

1;
