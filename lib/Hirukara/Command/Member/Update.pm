package Hirukara::Command::Member::Update;
use Mouse;
use Log::Minimal;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id   => ( is => 'ro', isa => 'Str', required => 1 );
has member_name => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;

    if (my $member = $self->database->single(member => { member_id => $member_id }) )  {
        my $before = $member->member_name;
        my $after  = $self->member_name;
        $member->member_name($after);
        $member->update;
        $self->action_log([ member_id => $member_id, before_name => $before, after_name => $after ]);
    } else {
        infof "MEMBER_NOT_EXISTS: member_id=%s", $member_id;
    }
}

1;
