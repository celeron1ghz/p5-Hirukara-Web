package Hirukara::Model::Checklist;
use Mouse;
use Smart::Args;
use Log::Minimal;

with 'Hirukara::Model';

sub get_checklists   {
    my($self,$where)= @_;
    my $res = $self->database->search_joined(circle => [
        checklist   => [ INNER => { 'circle.id' => 'checklist.circle_id' } ],
        assign      => [ LEFT  => { 'circle.id' => 'assign.circle_id' } ],
        assign_list => [ LEFT  => { 'assign_list.id' => 'assign.assign_list_id' } ],
    ], $where, {
        order_by => [
            'circle.day ASC',
            'circle.circle_sym ASC',
            'circle.circle_num ASC',
            'circle.circle_flag ASC',
        ]
    });

    my $ret = []; 
    my $lookup = {};

    while ( my($circle,$checklist,$assign,$assign_list) = $res->next ) { 
        my $col = $lookup->{$circle->id};

        unless ($lookup->{$circle->id}) {
            $lookup->{$circle->id} = $col = { circle => $circle };
            push @$ret, $col
        }

        unless ($checklist->id && $col->{__favorite}->{$checklist->id})   {
            push @{$col->{favorite}}, $checklist;
            $col->{__favorite}->{$checklist->id} = $checklist;
        }

        next unless $assign_list->id;

        unless ($col->{__assign}->{$assign_list->id})   {
            push @{$col->{assign}}, $assign_list;
            $col->{__assign}->{$assign_list->id} = $assign;
        }
    }  

    return $ret;
}

sub delete_all_checklists   {
    args my $self,
         my $member_id => { isa => 'Str' };

    my $count = $self->database->delete(checklist => { member_id => $member_id });
    infof "DELETE_ALL_CHECKLIST: member_id=%s, count=%s", $member_id, $count;

    $self->__create_action_log(CHECKLIST_DELETE_ALL => {
        member_id => $member_id,
        count     => $count,
    });

    return $count;
}

1;
