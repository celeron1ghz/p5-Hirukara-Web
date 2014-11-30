package Hirukara::Model::Assign;
use Mouse;
use Smart::Args;
use Log::Minimal;

with 'Hirukara::Model';

### assign methods
sub get_assign_lists {
    my($self,$cond) = @_;
    [$self->database->search("assign_list", $cond)->all];
}

sub get_assign_lists_with_count {
    my $self = shift;
    my $assign = $self->database->search_by_sql(<<SQL);
SELECT assign_list.*, COUNT(assign.id) AS count FROM assign_list
    LEFT JOIN assign ON assign_list.id = assign.assign_list_id
    GROUP BY assign_list.id
SQL

    [$assign->all];
}

sub create_assign_list  {
    args my $self,
         my $comiket_no => { isa => 'Str' };

    my $ret = $self->database->insert(assign_list => { name => "新規作成リスト", member_id => undef, comiket_no => $comiket_no });
    infof "CREATE_ASSIGN_LIST: id=%s, name=%s, comiket_no=%s", $ret->id, $ret->name, $ret->comiket_no;

    $ret;
}

sub update_assign_list  {
    args my $self,
         my $member_id     => { isa => 'Str' },
         my $assign_id     => { isa => 'Str' },
         my $assign_member => { isa => 'Str' },
         my $assign_name   => { isa => 'Str' };

    my $assign = $self->database->single(assign_list => { id => $assign_id });
    my $member_updated;
    my $name_updated;

    if ($assign_member ne $assign->member_id) {
        my $before_assign_member = $assign->member_id;;
        $assign->member_id($assign_member);
        $member_updated++;
        infof "UPDATE_ASSIGN_MEMBER: assign_id=%s, updated_by=%s, before_member=%s, updated_name=%s", $assign->id, $member_id, $before_assign_member, $assign_member;

        $self->__create_action_log(ASSIGN_MEMBER_UPDATE => {
            updated_by     => $member_id,
            assign_id      => $assign->id,
            before_member  => $before_assign_member,
            updated_member => $assign_member,
        });
    }
    
    if ($assign_name ne $assign->name)   {
        my $before_name = $assign->name;
        $assign->name($assign_name);
        $name_updated++;
        infof "UPDATE_ASSIGN_NAME: assign_id=%s, updated_by=%s, before_name=%s, updated_name=%s", $assign->id, $member_id, $before_name, $assign_name;

        $self->__create_action_log(ASSIGN_NAME_UPDATE => {
            updated_by   => $member_id,
            assign_id    => $assign->id,
            before_name  => $before_name,
            updated_name => $assign_name,
        });
    }

    $assign->update if $member_updated or $name_updated;
}

1;
