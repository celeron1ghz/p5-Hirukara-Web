package Hirukara::Command::Assign::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has assign_list_id => ( is => 'ro', isa => 'Str', required => 1 );
has circle_ids     => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
has member_id      => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $assign_id = $self->assign_list_id;
    my $assign    = $self->db->single(assign_list => { id => $assign_id });

    my @ids = @{$self->circle_ids};
    my $now = time;
    my @created;

    for my $id (@ids)   {
        if ( !$self->db->single(assign => { assign_list_id => $assign->id, circle_id => $id }) )    {
            push @created, $self->db->insert_and_fetch_row(assign => { assign_list_id => $assign->id, circle_id => $id, created_at => $now });
        }
    }

    $self->actioninfo("割り当てを作成しました。",
        assign_list_id => $assign_id, created_assign => scalar(@created), exist_assign => @ids - @created, member_id => $self->member_id);

    \@created;
}

1;
