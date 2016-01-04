package Hirukara::Command::AssignList::Delete;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has list_id => ( is => 'ro', isa => 'Str', required => 1 );
has run_by  => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $id   = $self->list_id;
    my $list = $self->db->single(assign_list => { id => $id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'assign_list', id => $id, member_id => $self->run_by);

    my @assigns = $list->assigns
        and Hirukara::DB::AssignStillExistsException->throw(assign_list => $list);

    my $ret = $self->db->delete(assign_list => { id => $id });
    $self->actioninfo("割り当てリストを削除しました。", list_id => $id, name => $list->name, run_by => $self->run_by);
    $ret;
}

__PACKAGE__->meta->make_immutable;
