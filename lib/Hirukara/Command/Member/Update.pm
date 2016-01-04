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

    if (my $member = $self->db->single(member => { member_id => $member_id }) )  {
        my $before = $member->member_name || '';
        my $after  = decode_utf8 $self->member_name;
        $self->db->update(member => { member_name => $after });
        $self->actioninfo("メンバーの名前を変更しました。", member_id => $member_id, before_name => $before, after_name => $after);
    } else {
        $self->actioninfo("メンバーが存在しません。", not_exist_member_id => $member_id);
    }
}

__PACKAGE__->meta->make_immutable;
