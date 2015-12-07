package Hirukara::Command::Search::ByCircleType;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $id   = $self->id;
    my($sql,@bind) = $self->db->query_builder->select(undef, [
        ['circle.id'],
        ['circle.comiket_no'],
        ['circle.circle_name'],
        ['circle.circle_author'],
        ['circle.area'],
        ['circle.day'],
        ['circle.circle_sym'],
        ['circle.circle_num'],
        ['circle.circle_flag'],
        ['checklist.member_id'],
        ['checklist.count'],
        ['checklist.comment'],
        ['member.member_name' => 'member_name'],
    ], {
        'comiket_no' => 'ComicMarket88',
        'circle.circle_type' => $id,
    }, {
        joins => [
            [ circle => { table => 'checklist', condition => 'circle.id = checklist.circle_id', type => 'LEFT' }], 
            [ circle => { table => 'member',    condition => 'checklist.member_id = member.member_id', type => 'LEFT' }], 
        ],  
    }); 

    my $ret = $self->db->search_by_sql($sql, \@bind);
    my @ret;
    while( my $col = $ret->next )   {
        if (my $last = $ret[-1])    {
            if ($col->id eq $last->id)  {
                push @{$last->checklists}, $col;
            } else {
                $col->checklists([$col]);
                push @ret, $col;
            }
        } else {
            $col->checklists([$col]);
            push @ret, $col;
        }
    }

    \@ret;
}

1;
