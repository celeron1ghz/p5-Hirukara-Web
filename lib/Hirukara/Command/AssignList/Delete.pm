package Hirukara::Command::AssignList::Delete;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has assign_list_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id      => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $id   = $self->assign_list_id;
    my $list = $self->db->single(assign_list => { id => $id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'assign_list', id => $id, member_id => $self->member_id);

    my @assigns = $list->assigns
        and Hirukara::DB::AssignStillExistsException->throw(assign_list => $list);

    my $ret = $self->db->delete(assign_list => { id => $id });
    $self->actioninfo("割り当てリストを削除しました。", assign_list_id => $id, name => $list->name, member_id => $self->member_id);
    $ret;
}

1;
