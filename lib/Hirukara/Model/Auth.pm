package Hirukara::Model::Auth;
use Mouse;
use Smart::Args;
use Log::Minimal;

with 'Hirukara::Model';

sub has_role    {
    args my $self,
         my $member_id => { isa => 'Str' },
         my $role_type => { isa => 'Str' };

    my $ret = $self->database->single(member_role => { member_id => $member_id, role_type => $role_type });

    if ($ret)   {
        infof "AUTH_SUCCESS: member_id=%s, role=%s", $member_id, $role_type;
        return $ret;
    } else {
        infof "AUTH_FAILTURE: member_id=%s, role=%s", $member_id, $role_type;
        return;
    }
}

1;


