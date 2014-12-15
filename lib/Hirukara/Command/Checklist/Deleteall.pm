package Hirukara::Command::Checklist::Deleteall;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id  => ( is => 'ro', isa => 'Str', required => 1 );
has exhibition => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my($sql,@bind) = $self->database->sql_builder->delete(checklist => {
        member_id => $self->member_id,
        circle_id => \["IN (SELECT id FROM circle WHERE comiket_no = ?)", $self->exhibition],
    });

    my $ret = $self->database->do($sql, {}, @bind);
    $self->action_log([ member_id => $self->member_id, exhibition => $self->exhibition, count => $ret ]);
    $ret;
}

1;
