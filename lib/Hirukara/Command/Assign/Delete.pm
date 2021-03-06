package Hirukara::Command::Assign::Delete;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has id     => ( is => 'ro', isa => 'Str', required => 1 );
has run_by => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self   = shift;
    my $id     = $self->id;
    my $assign = $self->db->single(assign => { id => $id });
    $self->db->delete($assign) if $assign;
    $self->actioninfo("割り当てを削除しました。" => id => $id, circle_id => $assign->circle_id, run_by => $self->run_by);
}

__PACKAGE__->meta->make_immutable;
