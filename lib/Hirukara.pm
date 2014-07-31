package Hirukara;
use Mouse;
use Hirukara::Util;
use Hirukara::Excel;
use Hirukara::Merge;
use Hirukara::Parser::CSV;
use Log::Minimal;
use JSON;
use Smart::Args;

has database => ( is => 'ro', isa => 'Teng', required => 1 );

sub get_circle_by_id    {
    args my $self,
         my $id => { isa => 'Str' };

    $self->database->single(circle => { id => $id });
}

sub get_checklists_by_circle_id {
    my($self,$id) = @_;
    $self->database->search(checklist => { circle_id => $id });
}

sub get_checklist   {
    my($self,$param) = @_;
    $self->database->single(checklist => { circle_id => $param->{circle_id}, member_id => $param->{member_id} });
}

sub get_checklists   {
    my($self,$where)= @_;
    my $res = $self->database->search_joined(circle => [
        checklist => [ LEFT => { 'circle.id' => 'checklist.circle_id' } ],
        assign    => [ LEFT => { 'circle.id' => 'assign.circle_id' } ],
        assign_list  => [ LEFT => { 'assign_list.id' => 'assign.assign_list_id' } ],
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
    my($self,$param) = @_;
    $self->get_checklist({ member_id => $param->{member_id}, circle_id => $param->{circle_id} }) and return;

    my $ret = $self->database->insert(checklist => $param);
    my $circle = $self->get_circle_by_id(id => $param->{circle_id});

    $self->__create_action_log(CHECKLIST_CREATE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $param->{member_id},
    });

    $ret;
}

sub delete_checklist    {
    my($self,$param) = @_;
    my $check = $self->get_checklist($param) or return;
    $check->delete;

    my $circle = $self->get_circle_by_id(id => $check->circle_id);

    $self->__create_action_log(CHECKLIST_DELETE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $check->member_id,
    });
}

sub update_checklist_info   {
    my($self,$param) = @_;
    my $check = $self->get_checklist({ member_id => $param->{member_id}, circle_id => $param->{circle_id} }); 
    return unless $check;

    my $before_cnt = $check->count;
    my $before_comment = $check->comment;
    $check->count($param->{order_count});
    $check->comment($param->{comment});
    $check->update;

    my $circle = $self->get_circle_by_id(id => $check->circle_id);

    $self->__create_action_log(CHECKLIST_ORDER_COUNT_UPDATE => {
        circle_id       => $check->circle_id,
        circle_name     => $circle->circle_name,
        member_id       => $check->member_id,
        before_cnt      => $before_cnt,
        after_cnt       => $check->count,
        comment_changed => ($before_comment eq $check->comment ? "NOT_CHANGE" : "CHANGED"),
    });

    $check;
}

sub get_member_by_id    {
    my($self,$id) = @_;
    $self->database->single(member => { id => $id });
}

sub create_member   {
    my($self,$param) = @_;
    my $ret = $self->database->insert(member => $param);

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

sub get_xls_file    {
    my($self) = @_;
    my $e = Hirukara::Excel->new(checklists => $self->get_checklists);
    $e->process;
    $e;
}

1;
