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
    my $res = $self->database->search_joined(circle => [
        checklist => { 'circle.id' => 'checklist.circle_id' },
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

    while ( my($circle,$checklist) = $res->next ) { 
        my $col = $lookup->{$circle->id};

        unless ($lookup->{$circle->id}) {
            $lookup->{$circle->id} = $col = { circle => $circle };
            push @$ret, $col
        }

        push @{$col->{favorite}}, $checklist;
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

sub update_checklist_info   {
    my($self,$param) = @_;
    my $check = $self->get_checklist({ member_id => $param->{member_id}, circle_id => $param->{circle_id} }); 
    return unless $check;

    my $before_cnt = $check->count;
    my $before_comment = $check->comment;
    $check->count($param->{order_count});
    $check->comment($param->{comment});
    $check->update;

    my $circle = $self->get_circle_by_id($check->circle_id);

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
    my $checks = $self->get_checklists;

use utf8;
use File::Temp();

    my $row = 3;
    my @cols = (
        {
            width  => 30,
            header => "サークル名",
            key    => "circle_name",
        },
        {
            width  => 30,
            header => "作者",
            key    => "circle_author",
        },
        {
            width  => 30,
            header => "スペース",
            key    => Hirukara::Util->can('get_circle_space')
        },
        {
            width  => 10,
            header => "冊数/人数",
            key    => sub {
                my($circle,$favorite) = @_;
                my $total = 0;
                $total += $_->count for @$favorite;
                sprintf "%s冊/%s人", $total, scalar @$favorite;
            },
        },
        {
            width  => 40,
            header => "コメント",
            key    => sub {
                my($circle,$favorite) = @_;
                my @ret;
                for my $f (@$favorite) {
                    my $val = sprintf "%s(%s)%s", $f->member_id, $f->count, $f->comment ? ":" . $f->comment : "";
                    if ($f->comment) { unshift @ret, $val }
                    else             { push @ret, $val }
                }
                return join "\n", @ret;
            },
        },
 
    );

    my $fh = File::Temp->new;
    my $x = Excel::Writer::XLSX->new($fh->filename);

    my $s = $x->add_worksheet("moge");
    $s->set_portrait;
    $s->set_margins_TB(0.2);
    $s->set_margins_LR(0.3);

    my $header = $x->add_format();
    $header->set_bold;
    $header->set_border;
    $header->set_align("center");
    $header->set_bg_color($x->set_custom_color(34, "#cccccc"));

    my $body = $x->add_format();
    $body->set_border;
    $body->set_size(8);

    for ( my $i = 0; $i < @cols; $i++ ) {
        my $col = $cols[$i];
        $s->set_column($i, $i, $col->{width});
        $s->write(2, $i, $col->{header}, $header);
    }

    for my $data (@$checks) {
        my $circle = $data->{circle};
        my $favorite = $data->{favorite};


        for ( my $col = 0; $col < @cols; $col++ )   {
            my $ret = $cols[$col]->{key};
            my $val = ref $ret eq 'CODE' ? $ret->($circle,$favorite) : $circle->$ret;
            $s->write($row, $col, $val, $body);
        }

        $row++;
    }

    $x->close;
    return $fh;
}

1;
