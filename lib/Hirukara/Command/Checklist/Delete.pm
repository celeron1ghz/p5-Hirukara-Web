package Hirukara::Command::Checklist::Delete;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self      = shift;
    my $circle_id = $self->circle_id;
    my $circle    = $self->db->single(circle => { id => $circle_id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'circle', id => $circle_id);

    my $ret = $self->db->delete(checklist => { circle_id => $self->circle_id, member_id => $self->member_id });
    $self->actioninfo("チェックリストを削除しました。", circle => $circle, member_id => $self->member_id, count => $ret || 0);
    $ret;
}

1;
