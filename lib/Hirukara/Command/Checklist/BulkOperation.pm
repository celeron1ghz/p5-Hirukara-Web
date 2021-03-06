package Hirukara::Command::Checklist::BulkOperation;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id      => ( is => 'ro', isa => 'Str', required => 1 );
has create_chk_ids => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has delete_chk_ids => ( is => 'ro', isa => 'ArrayRef', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;

    $self->actioninfo("サークルの一括追加・一括削除を行います。",
        member_id => $member_id, create_count => scalar @{$self->create_chk_ids} || 0, delete_count => scalar @{$self->delete_chk_ids} || 0);

    for my $id (@{$self->create_chk_ids})   {
        $self->hirukara->run_command('checklist.create' => {
            member_id => $member_id,
            circle_id => $id,
        });
    }

    for my $id (@{$self->delete_chk_ids})   {
        $self->hirukara->run_command('checklist.delete' => {
            member_id => $member_id,
            circle_id => $id,
        });
    }
}

__PACKAGE__->meta->make_immutable;
