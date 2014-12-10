package Hirukara::Command::Checklist::Joined;
use Mouse;
use SQL::QueryMaker;

with 'MouseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has where => ( is => 'ro', isa => 'Any|Undef' );

sub run {
    my $self = shift;
    my $where = $self->where;

    if (my $e = $self->exhibition)  {
        if (ref $where eq "HASH")   {
            $where->{'circle.comiket_no'} = $e;
        } elsif (ref $where eq 'SQL::QueryMaker') {
            $where = sql_and([ sql_eq("circle.comiket_no" => $e), $where ]);
        }
    }

    my $res = $self->database->search_joined(circle => [
        checklist   => [ INNER => { 'circle.id' => 'checklist.circle_id' } ],
        assign      => [ LEFT  => { 'circle.id' => 'assign.circle_id' } ],
        assign_list => [ LEFT  => { 'assign_list.id' => 'assign.assign_list_id' } ],
        member      => [ LEFT  => { 'member.member_id' => 'checklist.member_id' } ],
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

    while ( my($circle,$checklist,$assign,$assign_list,$member) = $res->next ) { 
        my $col = $lookup->{$circle->id};

        unless ($lookup->{$circle->id}) {
            $lookup->{$circle->id} = $col = { circle => $circle };
            push @$ret, $col
        }   

        unless ($checklist->id && $col->{__favorite}->{$checklist->id})   {   
            my $chk = $checklist->get_columns;
            $chk->{member} = $member;
            push @{$col->{favorite}}, $chk;
            $col->{__favorite}->{$checklist->id} = $chk;
        }   

        next unless $assign_list->id;

        unless ($col->{__assign}->{$assign_list->id})   {   
            push @{$col->{assign}}, $assign_list;
            $col->{__assign}->{$assign_list->id} = $assign;
        }   
    }   

    return $ret;
}

1;
