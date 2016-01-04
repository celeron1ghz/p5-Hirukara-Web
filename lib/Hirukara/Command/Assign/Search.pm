package Hirukara::Command::Assign::Search;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $builder = $self->db->query_builder;
    my $where = {};

    $where->{'assign_list.comiket_no'} = $self->hirukara->exhibition if $self->hirukara->exhibition;
    $where->{'assign_list.member_id'}  = $self->member_id  if $self->member_id;

    my $inner = <<SQL;
SELECT 
    assign_list.id,
    COUNT(DISTINCT assign.id)                   AS assign_count,
    COUNT(DISTINCT circle.id)                   AS circle_count,
    SUM(circle_order.count)                     AS book_count,
    SUM(circle.circle_point)                    AS point,
    SUM(circle_book.price * circle_order.count) AS book_price
FROM circle
    INNER JOIN assign        ON circle.id = assign.circle_id
    INNER JOIN assign_list   ON assign_list.id = assign.assign_list_id
    INNER JOIN circle_book   ON circle.id = circle_book.circle_id
    INNER JOIN circle_order  ON circle_order.book_id = circle_book.id
GROUP BY assign_list.id
SQL

    my($sql,@binds) = $builder->select(undef, [
        [ 'assign_list.id' ],
        [ 'assign_list.name' ],
        [ 'assign_list.member_id' ],
        [ 'assign_list.comiket_no' ],
        [ 'assign_list.created_at' ],

        [ 'member.member_name' ],

        [ 'counted.assign_count' ],
        [ 'counted.circle_count' ],
        [ 'counted.book_count' ],
        [ 'counted.book_price' ],
        [ 'counted.point' ],
    ], $where, {
        joins => [
            [ assign_list => { table => 'assign',            condition => 'assign_list.id = assign.assign_list_id', type => 'LEFT' }], 
            [ assign_list => { table => 'member',            condition => 'assign_list.member_id = member.member_id', type => 'LEFT' }], 
            [ assign_list => { table => \"($inner) counted", condition => 'assign_list.id = counted.id', type => 'LEFT' }],
        ],  
        group_by => 'assign_list.id',
        order_by => 'assign_list.name ASC',
    });

    my $it = $self->db->search_by_sql($sql, \@binds);
    $it;
}

__PACKAGE__->meta->make_immutable;
