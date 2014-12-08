package Hirukara::Command::Checklist::Joined;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has where => ( is => 'ro', isa => 'Any' );

sub run {
    my $self = shift;
    my $where = $self->where;

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

1;
