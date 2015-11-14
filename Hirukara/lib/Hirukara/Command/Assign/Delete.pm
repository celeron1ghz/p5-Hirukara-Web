package Hirukara::Command::Assign::Delete;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has id        => ( is => 'ro', isa => 'Str' );
has member_id => ( is => 'ro', isa => 'Str' );

sub run {
    my $self   = shift;
    my $id     = $self->id;
    my $assign = $self->db->single(assign => { id => $id });
    $assign->delete if $assign;
    $self->actioninfo(undef, "割り当てを削除しました。" => id => $id, member_id => $self->member_id, circle_id => $assign->circle_id);
}

1;
