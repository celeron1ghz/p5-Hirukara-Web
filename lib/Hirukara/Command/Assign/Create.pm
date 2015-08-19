package Hirukara::Command::Assign::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has assign_list_id => ( is => 'ro', isa => 'Str', required => 1 );
has circle_ids     => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );

sub run {
    my $self = shift;
    my $assign_id = $self->assign_list_id;
    my $assign    = $self->database->single(assign_list => { id => $assign_id });

    my @ids = @{$self->circle_ids};
    my @created;

    for my $id (@ids)   {
        if ( !$self->database->single(assign => { assign_list_id => $assign->id, circle_id => $id }) )    {
            push @created, $self->database->insert(assign => { assign_list_id => $assign->id, circle_id => $id });
        }
    }

    $self->logger->ainfo("割り当てを作成しました。",
        [ assign_list_id => $assign_id, created_assign => scalar @created, exist_assign => @ids - @created ]);

    \@created;
}

1;
