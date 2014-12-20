package Hirukara::Command::Checklist::Joined;
use Mouse;
use SQL::QueryMaker;
use Hash::MultiValue;
use Tie::IxHash;

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
        } else {
            $where = {'circle.comiket_no' => $e };
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

    my %circles;
    my @circles;
    my @circle_checks;
    my %assigns;
    my @circle_assigns;
    tie my %checks, 'Tie::IxHash';

    while ( my($circle,$checklist,$assign,$assign_list,$member) = $res->next ) { 

        if (!$circles{$circle->id}) {
            push @circles, $circle;

            $circles{$circle->id} = $circle;
        }

        if ($checklist->id and !$checks{$checklist->id})   {
            $checks{$checklist->id} = $checklist;
            $checklist->member($member);

            push @circle_checks, $checklist->circle_id, $checklist;
        }


        if ($assign->id and !$assigns{$assign->id})  {
            $assigns{$assign->id} = $assign;
            $assign_list->assign($assign);

            push @circle_assigns, $assign->circle_id, $assign_list;
        }
    }   

    my $circle_checks = Hash::MultiValue->new(@circle_checks);
    my $circle_assigns = Hash::MultiValue->new(@circle_assigns);

    for my $circle (@circles)   {
        my $id = $circle->id;
        $circle->checklists([ $circle_checks->get_all($id) ]);
        $circle->assigns([ $circle_assigns->{$id} ]);
    }

    return \@circles;
}

1;
