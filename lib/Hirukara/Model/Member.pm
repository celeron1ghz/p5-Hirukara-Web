package Hirukara::Model::Member;
use Mouse;
use Smart::Args;
use Log::Minimal;

with 'Hirukara::Model';

sub get_member_by_id    {
    args my $self,
         my $id => { isa => 'Str' };

    $self->database->single(member => { id => $id });
}

sub create_member   {
    args my $self,
         my $id        => { isa => 'Int' },
         my $member_id => { isa => 'Str' },
         my $image_url => { isa => 'Str' };

    my $ret = $self->database->insert(member => {
        id        => $id,
        member_id => $member_id,
        image_url => $image_url,
    });

    infof "CREATE_MEMBER: id=%s, member_id=%s", $id, $member_id;

    $self->__create_action_log(MEMBER_CREATE => {
        member_name => $ret->member_id,
    });

    $ret;
}

1;
