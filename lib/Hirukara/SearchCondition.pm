package Hirukara::SearchCondition;
use utf8;
use strict;
use warnings;

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
    my($class,$params) = @_;
    my $stash = { map { $_ => [] } keys %METHODS };

    for my $row (@CALLBACKS)    {
        my $param   = $params->{$row->{param_key}} or next;
        my $process = $row->{process};
        my $result  = $row->{method}->($param);

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
use Hirukara::Constants::Area;
use Hirukara::Constants::CircleType;

add_column(day => {
    condition_label => sub { sprintf "%s日目", @_ },
    condition => sub {
        my $param = shift;
        sql_eq(day => $param);
    },
});


add_column(area => {
    condition_label => sub { sprintf "エリア=%s", @_ },
    condition => sub {
        my $param = shift;
        my $syms = Hirukara::Constants::Area->get_syms_by_area($param) or return;;
        sql_in('circle.circle_sym' => $syms)
    }
});

add_column(circle_name => {
    condition_label => sub { sprintf "サークル名=%s", @_ },
    condition => sub {
        my $param = shift;
        sql_like('circle.circle_name' => "%$param%");
    }
});

add_column(circle_type => {
    condition_label => sub {
        my $param = shift;
        my $type = Hirukara::Constants::CircleType::lookup($param) or return;
        sprintf "サークル属性=%s", $type->{label};
    },
    condition => sub {
        my $param = shift;
        sql_eq(circle_type => $param);
    },
});


add_column(member_id => {
    condition_label => sub { sprintf "メンバー=%s", @_ },
    condition => sub {
        my $param = shift;
        sql_op('circle.id' => "IN (SELECT circle_id FROM checklist WHERE member_id = ?)", [$param]);
    }
});

add_column(assign => {
    condition_label => sub { sprintf "割当=ID:%s", @_ },
    condition => sub {
        my $param = shift;
            $param eq "-1"
                ? sql_op('circle.id' => "IN (SELECT circle.id AS circle_id FROM circle LEFT JOIN assign ON circle.id = assign.circle_id WHERE assign.circle_id IS NULL)", [])
                : sql_op('circle.id' => "IN (SELECT circle_id FROM assign WHERE assign_list_id = ?)", [$param])
    },
});

1;
