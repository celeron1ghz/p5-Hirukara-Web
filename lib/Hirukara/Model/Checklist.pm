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

=for

sub create_checklist    {
    args my $self,
         my $circle_id => { isa => 'Str' },
         my $member_id => { isa => 'Str' };

    $self->get_checklist(member_id => $member_id, circle_id => $circle_id) and return;

    my $ret = $self->database->insert(checklist => { circle_id => $circle_id, member_id => $member_id, count => 1 });
    infof "CREATE_CHECKLIST: member_id=%s, circle_id=%s", $member_id, $circle_id;

    my $circle = $self->database->single(circle => { id => $circle_id });

    $self->__create_action_log(CHECKLIST_CREATE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $member_id,
    });

    $ret;
}

sub update_checklist_info   {
    args my $self,
         my $member_id   => { isa => 'Str' },
         my $circle_id   => { isa => 'Str' },
         my $comment     => { optional => 1, default => "" },
         my $order_count => { isa => 'Int', optional => 1, default => "" };

    my $check = $self->get_checklist(member_id => $member_id, circle_id => $circle_id) or return;
    my $before_count = $check->count;
    my $comment_changed;
    my $count_changed;

    if ($comment ne ($check->comment || ''))    {
        $check->comment($comment);
        $comment_changed++;
        infof "UPDATE_CHECKLIST_COMMENT: checklist_id=%s, member_id=%s", $check->id, $member_id;
    }

    if ($order_count ne "" and $order_count ne $check->count)  {
        $check->count($order_count);
        $count_changed++;
        infof "UPDATE_CHECKLIST_COUNT: checklist_id=%s, member_id=%s, before=%s, after=%s", $check->id, $member_id, $before_count, $order_count;
    }

    if ($comment_changed or $count_changed) {
        $check->update;

        my $circle = $self->database->single(circle => { id => $check->circle_id });

        $self->__create_action_log(CHECKLIST_ORDER_COUNT_UPDATE => {
            circle_id       => $check->circle_id,
            circle_name     => $circle->circle_name,
            member_id       => $check->member_id,
            before_cnt      => $before_count,
            after_cnt       => $check->count,
            comment_changed => ($comment_changed ? "NOT_CHANGE" : "CHANGED"),
        });

        $check;
    }
    else    {
        return;
    }
}

sub delete_checklist    {
    args my $self,
         my $member_id => { isa => 'Str' },
         my $circle_id => { isa => 'Str' };

    my $check = $self->get_checklist(member_id => $member_id, circle_id => $circle_id) or return;
    $check->delete;
    infof "DELETE_CHECKLIST: checklist_id=%s, member_id=%s, circle_id=%s", $check->id, $member_id, $circle_id;

    my $circle = $self->database->single(circle => { id => $check->circle_id });

    $self->__create_action_log(CHECKLIST_DELETE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $check->member_id,
    });

    return 1;
}

=cut

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
