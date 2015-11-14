package Hirukara::Command::Member::Update;
use utf8;
use Moose;
use Encode;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id   => ( is => 'ro', isa => 'Str', required => 1 );
has member_name => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;

    if (my $member = $self->hirukara->db->single(member => { member_id => $member_id }) )  {
        my $before = $member->member_name || '';
        my $after  = decode_utf8 $self->member_name;
        $member->member_name($after);
        $member->update;
        $self->hirukara->actioninfo(undef, "メンバーの名前を変更しました。", member_id => $member_id, before_name => $before, after_name => $after);
    } else {
        $self->hirukara->actioninfo(undef, "メンバーが存在しません。", member_id => $member_id);
    }
}

1;
