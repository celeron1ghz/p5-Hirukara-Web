package Hirukara;
use Mouse;
use Hirukara::Merge;
use Hirukara::Util;
use Hirukara::Parser::CSV;
use Excel::Writer::XLSX;
use Log::Minimal;
use JSON;

has database => ( is => 'ro', isa => 'Teng', required => 1 );

sub get_circle_by_id    {
    my($self,$id) = @_;
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
    my $res = $self->database->search_joined(checklist => [
        circle => { 'circle.id' => 'checklist.circle_id' },
    ], $where);

    my $ret = {}; 

    while ( my($checklist,$circle) = $res->next ) { 
        $ret->{$circle->id}->{circle} = $circle;

        push @{$ret->{$circle->id}->{favorite}}, $checklist;
    }  

    return $ret;
}

sub create_checklist    {
    my($self,$param) = @_;
    my $ret = $self->database->insert(checklist => $param);
    my $circle = $self->get_circle_by_id($param->{circle_id});

    $self->__create_action_log(CHECKLIST_CREATE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $param->{member_id},
    });

    $ret;
}

sub delete_checklist    {
    my($self,$obj) = @_;
    $obj->delete;
    my $circle = $self->get_circle_by_id($obj->circle_id);

    $self->__create_action_log(CHECKLIST_DELETE => {
        circle_id   => $circle->id,
        circle_name => $circle->circle_name,
        member_id   => $obj->member_id,
    });
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
    $self->database->search(action_log => {});
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
    my $checks = $self->get_checklists;

    my $row = 3;
    my @cols = (
        { key => "circle_name" },
        { key => "circle_author" },
        { key => Hirukara::Util->can('get_circle_space') },
    );

    my $x = Excel::Writer::XLSX->new("moge.xlsx");
    my $s = $x->add_worksheet("moge");

    $s->set_column(0, 0, 30);
    $s->set_column(1, 1, 30);
    $s->set_column(2, 2, 30);

    while( my($id,$data) = each %$checks )    {
        my $circle = $data->{circle};

        for ( my $col = 0; $col < @cols; $col++ )   {
            my $ret = $cols[$col]->{key};
            my $val = ref $ret eq 'CODE' ? $ret->($circle) : $circle->$ret;
            $s->write($row, $col, $val);
        }

        $row++;
    }

    $x->close;

    return 1;
}

1;
