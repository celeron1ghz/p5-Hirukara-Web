package Hirukara::Command::Checklist::Delete;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret = $self->database->delete(checklist => {
        circle_id => $self->circle_id,
        member_id => $self->member_id,
    });

    $self->action_log([ circle_id => $self->circle_id, member_id => $self->member_id, count => $ret ]);
    $ret;
}

1;
