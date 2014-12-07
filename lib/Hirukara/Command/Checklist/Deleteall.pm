package Hirukara::Command::Checklist::Deleteall;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret = $self->database->delete(checklist => { member_id => $self->member_id });

    $self->action_log(member_id => $self->member_id, count => $ret);
    $ret;
}

1;
