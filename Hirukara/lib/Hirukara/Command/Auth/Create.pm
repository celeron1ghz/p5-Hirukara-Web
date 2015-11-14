package Hirukara::Command::Auth::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );
has role_type => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $cond = { member_id => $self->member_id, role_type => $self->role_type };

    if (my $auth = $self->db->single(member_role => $cond) )  {
        $self->actioninfo(undef, "権限が既に存在します。" => member_id => $auth->member_id, role => $auth->role_type);
        return;
    }

    $cond->{created_at} = time;
    my $ret = $self->db->insert(member_role => $cond);
    $self->actioninfo(undef, "権限を作成しました。", id => $ret->id, member_id => $ret->member_id, role => $ret->role_type);
    $ret;
}

1;
