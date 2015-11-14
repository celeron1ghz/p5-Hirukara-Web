package Hirukara::Command::Checklist::Delete;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $circle_id = $self->circle_id;
    my $circle    = $self->hirukara->db->single(circle => { id => $circle_id })
        or Hirukara::Circle::CircleNotFoundException->throw("no such circle id=$circle_id");

    my $ret = $self->hirukara->db->delete(checklist => { circle_id => $self->circle_id, member_id => $self->member_id });
    $self->hirukara->actioninfo(undef, "チェックリストを削除しました。", circle_id => $self->circle_id, member_id => $self->member_id, count => $ret);
    $ret;
}

1;
