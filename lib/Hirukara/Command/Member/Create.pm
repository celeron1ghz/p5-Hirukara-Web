package Hirukara::Command::Member::Create;
use Moose;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command';

has id          => ( is => 'ro', isa => 'Str', required => 1 );
has member_id   => ( is => 'ro', isa => 'Str', required => 1 );
has member_name => ( is => 'ro', isa => 'Str', required => 1 );
has image_url   => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;

    if (my $member = $self->database->single(member => { member_id => $self->member_id }) )  {
        infof "MEMBER_EXISTS: member_id=%s", $member->member_id;
        return;
    }

    my $ret = $self->database->insert(member => {
        id          => $self->id,
        member_id   => $self->member_id,
        member_name => $self->member_name,
        image_url   => $self->image_url,
    });

    $self->action_log([ id => $ret->id, member_id => $ret->member_id ]);
    $ret;
}

1;
