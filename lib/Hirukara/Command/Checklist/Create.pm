package Hirukara::Command::Checklist::Create;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;
    my $circle_id = $self->circle_id;

    $self->database->single(checklist => { member_id => $member_id, circle_id => $circle_id }) and return;

    my $ret = $self->database->insert(checklist => { circle_id => $circle_id, member_id => $member_id, count => 1 }); 
    $self->action_log(member_id => $member_id, circle_id => $circle_id);

=for

    my $circle = $self->database->single(circle => { id => $circle_id }); 

    $self->__create_action_log(CHECKLIST_CREATE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $member_id,
    }); 

=cut

    $ret;
}

1;
