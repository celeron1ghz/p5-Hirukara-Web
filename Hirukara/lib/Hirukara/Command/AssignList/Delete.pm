package Hirukara::Command::AssignList::Delete;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has assign_list_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id      => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $id = $self->assign_list_id;
    my $hi = $self->hirukara;
    my $db = $self->hirukara->db;
    my($sql,@binds) = $db->sql_builder->select(undef, [
        [ 'assign_list.name'  => 'name' ],
        [ \'COUNT(assign.id)' => 'count' ],
    ], {
        'assign_list.id' => $id,
    }, {
        joins => [
            [ assign_list => { table => 'assign', condition => 'assign_list.id = assign.assign_list_id', type => 'LEFT' }], 
        ],  
    }); 

    my $cnt = $db->single_by_sql($sql, \@binds);
    if ($cnt->count != 0)   {
        $hi->actioninfo(undef, "割当リストにまだ割当が存在します。", assign_list_id => $id, name => $cnt->name, member_id => $self->member_id);
        Hirukara::AssignList::AssignExistException->throw("割当リスト内にまだ割当が存在します。");
    }

    my $ret = $db->delete(assign_list => { id => $id });
    $hi->actioninfo(undef, "割り当てリストを削除しました。", assign_list_id => $id, name => $cnt->name, member_id => $self->member_id);
    $ret;
}

1;
