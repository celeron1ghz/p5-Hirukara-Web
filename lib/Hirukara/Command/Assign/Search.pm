package Hirukara::Command::Assign::Search;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

sub run {
    my $self = shift;
    my $builder = $self->database->sql_builder;
    my $where = {};

    if (my $e = $self->exhibition)  {
        $where->{'assign_list.comiket_no'} = $e;
    }

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
        group_by => 'assign_list.id'
    });

    my $it = $self->database->search_by_sql($sql, \@binds);
    $it;
}

1;
