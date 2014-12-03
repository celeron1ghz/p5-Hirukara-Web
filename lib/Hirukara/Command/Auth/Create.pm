package Hirukara::Command::Auth::Create;
use Mouse;
use Log::Minimal;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );
has role_type => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $cond = { member_id => $self->member_id, role_type => $self->role_type };

    if (my $auth = $self->database->single(member_role => $cond) )  {
        infof "AUTH_EXISTS: member_id=%s, role=%s", $auth->member_id, $auth->role_type;
        return;
    }

    my $ret = $self->database->insert(member_role => $cond);
    infof "AUTH_CREATE: id=%s, member_id=%s, role=%s", $ret->id, $ret->member_id, $ret->role_type;
    $ret;
}

1;
