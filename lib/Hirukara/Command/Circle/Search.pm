package Hirukara::Command::Circle::Search;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has where => ( is => 'ro', isa => 'SQL::QueryMaker', required => 1 );

sub run {
    my $self = shift;
    my $where = $self->where;

    my $it = $self->database->search_joined(circle => [
        checklist => [ LEFT => { 'circle.id' => 'checklist.circle_id' } ] 
    ],$where, {
        order_by => [
            'day ASC',
            'circle_sym ASC',
            'circle_num ASC',
            'circle_flag ASC',
        ]   
    }); 

    my %circles;
    my @ret;

    while ( my($circle,$chk) = $it->next )    {   
        if (my $cached = $circles{$circle->id})  {
            push @{$cached->{favorite}}, $chk;
        }   
        else    {   
            my $data = { circle => $circle, favorite => [$chk] };
            push @ret, $data;
            $circles{$circle->id} = $data;
        }   
    }   

    return \@ret;
}

1;
