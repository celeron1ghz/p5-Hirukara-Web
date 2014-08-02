package Hirukara;
use Mouse;
use Hirukara::Util;
use Hirukara::Excel;
use Hirukara::Merge;
use Hirukara::Parser::CSV;
use Hirukara::ComiketCsv;
use Log::Minimal;
use JSON;
use Smart::Args;

has database => ( is => 'ro', isa => 'Teng', required => 1 );

sub get_circle_by_id    {
    args my $self,
         my $id => { isa => 'Str' };

    $self->database->single(circle => { id => $id });
}

sub update_circle_info  {
    args my $self,
         my $member_id   => { isa => 'Str' },
         my $circle_id   => { isa => 'Str' },
         my $circle_type => { optional => 1, default => "" },
         my $comment     => { optional => 1, default => "" };

    my $circle = $self->get_circle_by_id(id => $circle_id) or return;
    my $comment_updated;
    my $type_updated;
    my $before_circle_type = $circle->circle_type;

    if ($circle_type ne ($circle->circle_type || ''))    {   
        $circle->circle_type($circle_type);
        $type_updated++;
    }   

    if ($comment ne ($circle->comment || ''))   {   
        $circle->comment($comment);
        $comment_updated++;
    }

    if ($comment_updated or $type_updated)  {
        $circle->update;

        if ($type_updated)   {
            infof "UPDATE_CIRCLE_TYPE: circle_id=%s, type=%s", $circle_id, $circle->circle_type;

            use Hirukara::Constants::CircleType;
            my $before = Hirukara::Constants::CircleType::lookup($before_circle_type);
            my $after  = Hirukara::Constants::CircleType::lookup($circle_type);

            $self->__create_action_log(CIRCLE_TYPE_UPDATE => {
                circle_id   => $circle->id,
                circle_name => $circle->circle_name,
                member_id   => $member_id,
                before_type => $before->{label},
                after_type  => $after->{label},
            });
        }

        if ($comment_updated)   {
            infof "UPDATE_CIRCLE_COMMENT: circle_id=%s", $circle_id;

            $self->__create_action_log(CIRCLE_COMMENT_UPDATE => {
                circle_id   => $circle->id,
                circle_name => $circle->circle_name,
                member_id   => $member_id,
            });
        }

        return $circle;
    }
    else {
        return;
    }
}

sub get_checklists_by_circle_id {
    my($self,$id) = @_;
    $self->database->search(checklist => { circle_id => $id });
}

sub get_checklist   {
    args my $self,
         my $circle_id => { isa => 'Str' },
         my $member_id => { isa => 'Str' };

    $self->database->single(checklist => { circle_id => $circle_id, member_id => $member_id });
}

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

        push @{$col->{favorite}}, $checklist;
        push @{$col->{assign}},   $assign_list;
    }  

    return $ret;
}

sub create_checklist    {
    args my $self,
         my $circle_id => { isa => 'Str' },
         my $member_id => { isa => 'Str' };

    $self->get_checklist(member_id => $member_id, circle_id => $circle_id) and return;

    my $ret = $self->database->insert(checklist => { circle_id => $circle_id, member_id => $member_id, count => 1 });
    infof "CREATE_CHECKLIST: member_id=%s, circle_id=%s", $member_id, $circle_id;

    my $circle = $self->get_circle_by_id(id => $circle_id);

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
    }

    if ($order_count ne "" and $order_count ne $check->count)  {
        $check->count($order_count);
        $count_changed++;
    }

    if ($comment_changed or $count_changed) {
        $check->update;

        infof "UPDATE_CHECKLIST_COUNT: id=%s, member_id=%s, before_cnt=%s, after_cnt=%s", $check->id, $member_id, $before_count, $order_count if $count_changed;
        infof "UPDATE_CHECKLIST_COMMENT: id=%s, member_id=%s", $check->id, $member_id if $comment_changed;

        my $circle = $self->get_circle_by_id(id => $check->circle_id);

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
    infof "DELETE_CHECKLIST: id=%s, member_id=%s, circle_id=%s", $check->id, $member_id, $circle_id;

    my $circle = $self->get_circle_by_id(id => $check->circle_id);

    $self->__create_action_log(CHECKLIST_DELETE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $check->member_id,
    });

    return 1;
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

sub get_member_by_id    {
    args my $self,
         my $id => { isa => 'Str' };

    $self->database->single(member => { id => $id });
}

sub create_member   {
    args my $self,
         my $id        => { isa => 'Int' },
         my $member_id => { isa => 'Str' },
         my $image_url => { isa => 'Str' };

    my $ret = $self->database->insert(member => {
        id        => $id,
        member_id => $member_id,
        image_url => $image_url,
    });

    infof "CREATE_MEMBER: id=%s, member_id=%s", $id, $member_id;

    $self->__create_action_log(MEMBER_CREATE => {
        member_name => $ret->member_id,
    });

    $ret;
}

sub __create_action_log   {
    my($self,$messid,$param) = @_;
    my $circle_id = $param->{circle_id};

    $self->database->insert(action_log => {
        message_id  => $messid,
        circle_id   => $circle_id,
        parameters  => encode_json $param,
    });
}

sub get_action_logs   {
    my($self) = @_;
    $self->database->search(action_log => {}, { order_by => { id => 'DESC' } });
}

sub merge_checklist {
    my($self,$csv,$member_id) = @_;
    my $ret = Hirukara::Merge->new(database => $self->database, csv => $csv, member_id => $member_id);

    $self->__create_action_log(CHECKLIST_MERGE => {
        member_id   => $member_id,
        create      => (scalar keys %{$ret->merge_results->{create}}),
        delete      => (scalar keys %{$ret->merge_results->{delete}}),
        exist       => (scalar keys %{$ret->merge_results->{exist}}),
        comiket_no  => $csv->comiket_no,
    });

    $ret;
}

sub parse_csv   {
    my($self,$path) = @_;
    my $ret = Hirukara::Parser::CSV->read_from_file($path);
    $ret;
}

sub export_csv  {
    my($self) = @_;
    my $csv = Hirukara::ComiketCsv->new(checklists => $self->get_checklists);
    $csv->process;
}

sub get_xls_file    {
    my($self) = @_;
    my $e = Hirukara::Excel->new(checklists => $self->get_checklists);
    $e->process;
    $e;
}

1;
