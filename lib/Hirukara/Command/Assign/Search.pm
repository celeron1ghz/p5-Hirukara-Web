package Hirukara::Command::Assign::Search;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has member_id => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $builder = $self->db->sql_builder;
    my $where = {};

    $where->{'assign_list.comiket_no'} = $self->exhibition if $self->exhibition;
    $where->{'assign_list.member_id'}  = $self->member_id  if $self->member_id;

    my($sql,@binds) = $builder->select(undef, [
        [ 'assign_list.id' ],
        [ 'assign_list.name' ],
        [ 'assign_list.member_id' ],
        [ 'member.member_name' ],
        [ 'assign_list.comiket_no' ],
        [ 'assign_list.created_at' ],
        [ \'COUNT(assign.id)' => 'count' ],
    ], $where, {
        joins => [
            [ assign_list => { table => 'assign', condition => 'assign_list.id = assign.assign_list_id', type => 'LEFT' }], 
            [ assign_list => { table => 'member', condition => 'assign_list.member_id = member.member_id', type => 'LEFT' }], 
        ],  
        group_by => 'assign_list.id',
        order_by => 'assign_list.name ASC',
    });

    my $it = $self->db->search_by_sql($sql, \@binds);
    $it;
}

1;
