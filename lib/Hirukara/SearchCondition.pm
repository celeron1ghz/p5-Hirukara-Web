package Hirukara::SearchCondition;
use utf8;
use Moose;

has database => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );

my @CALLBACKS;

my %METHODS = (
    condition_label => sub {
        my $val = shift;
        @$val ? join(", " => @$val) : 'なし';
    },
    condition => sub {
        my $val = shift;
        sql_and($val) if @$val;
    }
);


sub add_column  {
    my($column,$args) = @_;

    while ( my($key,$method) = each %$args )    {
        $METHODS{$key} or die "No such process $key";
        push @CALLBACKS, { process => $key, param_key => $column, method => $method };
    }
}


sub run {
    my($self,$params) = @_;
    my $stash = { map { $_ => [] } keys %METHODS };

    for my $row (@CALLBACKS)    {
        my $param   = $params->{$row->{param_key}};
            defined $param or next;

        my $process = $row->{process};
        my $result  = $row->{method}->($self,$param);

        push @{$stash->{$process}}, $result if defined $result;
    }

    my %ret;
    while ( my($key,$method) = each %METHODS )  {
        my $val = $stash->{$key};
        my $ret = $method->($val);
        $ret{$key} = $ret;
    }

    \%ret;
}

## declare columns
use SQL::QueryMaker;

add_column(day => {
    condition_label => sub {
        my($self,$val) = @_;
        $val or return;
        sprintf "%s日目", $val;
    },
    condition => sub {
        my($self,$param) = @_;
        $param or return;
        sql_eq(day => $param);
    },
});


#add_column(area => {
#    condition_label => sub {
#        my $self = shift;
#        sprintf "エリア=%s", @_;
#    },
#    condition => sub {
#        my($self,$param) = @_;
#        my $syms = Hirukara::Constants::Area->get_syms_by_area($param) or return;
#        sql_in('circle.circle_sym' => $syms)
#    }
#});

#add_column(circle_name => {
#    condition_label => sub {
#        my($self,$val) = @_;
#        sprintf "サークル名=%s", $val;
#    },
#    condition => sub {
#        my($self,$val) = @_;
#        sql_like('circle.circle_name' => "%$val%");
#    }
#});

add_column(circle_type => {
    condition_label => sub {
        my($self,$val) = @_;
        $val or return;
        my $type = $self->database->single(circle_type => { id => $val }) or return;
        sprintf "サークル属性=%s", $type->type_name
    },
    condition => sub {
        my($self,$val) = @_;
        $val or return;
        sql_eq(circle_type => $val);
    },
});


add_column(member_id => {
    condition_label => sub {
        my($self,$val) = @_;
        $val or return;
        my $member = $self->database->single(member => { member_id => $val });
        sprintf 'メンバー="%s"', $member ? sprintf("%s(%s)", $member->member_name, $member->member_id) : $val;
    },
    condition => sub {
        my($self,$val) = @_;
        $val or return;
        sql_op('circle.id' => "IN (SELECT circle_id FROM circle_book JOIN circle_order ON circle_book.id = circle_order.book_id WHERE circle_order.member_id = ?)", [$val]);
    }
});

add_column(assign => {
    condition_label => sub {
        my($self,$val) = @_;
        $val or return;
        my $assign = $self->database->single(assign_list => { id => $val });
        my $member = $assign ? $self->database->single(member => { member_id => $assign->member_id }) : undef;
        sprintf '割当="%s"', $assign
            ? sprintf("ID:%s %s[%s]", $assign->id, $assign->name, $member ? $member->member_name : $assign->member_id)
            : sprintf("ID:%s", $val);
    },
    condition => sub {
        my($self,$val) = @_;
        $val or return;
        $val eq "-1"
            ? sql_op('circle.id' => "IN (SELECT circle.id AS circle_id FROM circle LEFT JOIN assign ON circle.id = assign.circle_id WHERE assign.circle_id IS NULL)", [])
            : sql_op('circle.id' => "IN (SELECT circle_id FROM assign WHERE assign_list_id = ?)", [$val])
    },
});

add_column(unordered => {
    condition_label => sub {
        my($self,$val) = @_;
        $val ? '誰も発注していないサークルを含む' : undef;
    },
    condition => sub {
        my($self,$val) = @_;
        my $sql =  "IN ("
            . "SELECT circle_book.circle_id FROM circle_book LEFT JOIN circle_order ON circle_book.id = circle_order.book_id "
            . "WHERE circle_order.id IS NOT NULL)";
        $val ? undef : sql_op('circle.id' => $sql, []);
    }
});

1;
