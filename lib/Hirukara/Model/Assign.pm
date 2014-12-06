package Hirukara::Model::Assign;
use Mouse;
use Smart::Args;
use Log::Minimal;

with 'Hirukara::Model';

### assign methods
sub get_assign_lists {
    my($self,$cond) = @_;
    [$self->database->search("assign_list", $cond)->all];
}

sub get_assign_lists_with_count {
    my $self = shift;
    my $assign = $self->database->search_by_sql(<<SQL);
SELECT assign_list.*, COUNT(assign.id) AS count FROM assign_list
    LEFT JOIN assign ON assign_list.id = assign.assign_list_id
    GROUP BY assign_list.id
SQL

    [$assign->all];
}

sub update_assign   {
    args my $self,
         my $assign_id  => { isa => 'Str' },
         my $circle_ids => { isa => 'ArrayRef' };

    my $assign = $self->database->single(assign_list => { id => $assign_id });

    for my $id (@$circle_ids)   {   
        if ( !$self->database->single(assign => { assign_list_id => $assign->id, circle_id => $id }) )    {   
            my $list = $self->database->insert(assign => { assign_list_id => $assign->id, circle_id => $id }); 
        }   
    }
}

1;
