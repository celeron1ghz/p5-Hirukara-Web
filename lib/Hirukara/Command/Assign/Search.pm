package Hirukara::Command::Assign::Search;
use Mouse;
use Log::Minimal;

with 'MouseX::Getopt', 'Hirukara::Command';

sub run {
    my $self = shift;
    my $builder = $self->database->sql_builder;
    my $where = {};

    my($sql,@binds) = $builder->select(undef, [
        [ 'assign_list.id' ],
        [ 'assign_list.name' ],
        [ 'assign_list.member_id' ],
        [ 'assign_list.comiket_no' ],
        [ 'assign_list.created_at' ],
        [ \'COUNT(assign.id)' => 'count' ],
    ], $where, {
        joins => [
            [ assign_list => { table => 'assign', condition => 'assign_list.id = assign.assign_list_id', type => 'LEFT' }], 
        ],  
        group_by => 'assign_list.id'
    });

    my $it = $self->database->search_by_sql($sql, \@binds);
    $it;
}

1;
