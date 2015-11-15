package Hirukara::Command::Checklist::Joined;
use Moose;
use SQL::QueryMaker;
use Hash::MultiValue;
use Tie::IxHash;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

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

    my $res = $self->db->search_joined(circle => [
        checklist   => [ INNER => { 'circle.id' => 'checklist.circle_id' } ],
        assign      => [ LEFT  => { 'circle.id' => 'assign.circle_id' } ],
        assign_list => [ LEFT  => { 'assign_list.id' => 'assign.assign_list_id' } ],
        member      => [ LEFT  => { 'member.member_id' => 'checklist.member_id' } ],
        circle_type => [ LEFT  => { 'circle.circle_type' => 'circle_type.id' } ],
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
    my %assigns;
    tie my %checks, 'Tie::IxHash';

    my $circle_checks = Hash::MultiValue->new;
    my $circle_assigns = Hash::MultiValue->new;

    while ( my($circle,$checklist,$assign,$assign_list,$member,$type) = $res->next ) { 
        $circle->circle_types($type) if $type->id;

        if (!$circles{$circle->id}) {
            push @circles, $circle;

            $circles{$circle->id} = $circle;
        }

        if ($checklist->id and !$checks{$checklist->id})   {
            $checks{$checklist->id} = $checklist;
            $checklist->member($member);

            $circle_checks->add($checklist->circle_id, $checklist);
        }


        if ($assign->id and !$assigns{$assign->id})  {
            $assigns{$assign->id} = $assign;
            $assign_list->assign($assign);

            my $m = $self->db->single(member => { member_id => $assign_list->member_id });
            $assign_list->member($m);

            $circle_assigns->add($assign->circle_id, $assign_list);
        }
    }   

    for my $circle (@circles)   {
        my $id = $circle->id;
        $circle->checklists([ $circle_checks->get_all($id) ]);
        $circle->assigns([ $circle_assigns->get_all($id) ]);
    }

    return \@circles;
}

1;
