package Hirukara::Command::Member::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has id          => ( is => 'ro', isa => 'Str', required => 1 );
has member_id   => ( is => 'ro', isa => 'Str', required => 1 );
has member_name => ( is => 'ro', isa => 'Str', required => 1 );
has image_url   => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;

    if (my $member = $self->hirukara->db->single(member => { member_id => $self->member_id }) )  {
        $self->hirukara->actioninfo(undef, "メンバーが存在します。", member_id => $member->member_id);
        return;
    }

    my $ret = $self->hirukara->db->insert(member => {
        id          => $self->id,
        member_id   => $self->member_id,
        member_name => $self->member_name,
        image_url   => $self->image_url,
        created_at  => time,
    });

    $self->hirukara->actioninfo(undef, "メンバーを作成しました。", id => $ret->id, member_id => $ret->member_id);
    $ret;
}

1;
