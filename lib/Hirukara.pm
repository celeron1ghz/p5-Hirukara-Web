package Hirukara;
use Mouse;
use Hirukara::Merge;
use Hirukara::Parser::CSV;

has database => ( is => 'ro', isa => 'Teng', required => 1 );

sub get_circle_by_id    {
    my($self,$id) = @_;
    $self->database->single(circle => { id => $id });
}

sub get_checklists_by_circle_id {
    my($self,$id) = @_;
    $self->database->search(checklist => { circle_id => $id });
}

sub get_checklist   {
    my($self,$param) = @_;
    $self->database->single(checklist => { circle_id => $param->{circle_id}, member_id => $param->{member_id} });
}

sub get_checklists   {
    my($self,$where)= @_;
    my $res = $self->database->search_joined(checklist => [
        circle => { 'circle.id' => 'checklist.circle_id' },
    ], $where);

    my $ret = {}; 

    while ( my($checklist,$circle) = $res->next ) { 
        $ret->{$circle->id}->{circle} = $circle;

        push @{$ret->{$circle->id}->{favorite}}, $checklist;
    }  

    return $ret;
}

sub merge_checklist {
    my($self,$csv,$member_id) = @_;
    Hirukara::Merge->new(database => $self->database, csv => $csv, member_id => $member_id);
}

sub parse_csv   {
    my($self,$path) = @_;
    Hirukara::Parser::CSV->read_from_file($path);
}

1;
