package Hirukara::Command::Checklist::Bulkoperation;
use Mouse;
use Hirukara::Command::Checklist::Create;
use Hirukara::Command::Checklist::Delete;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id      => ( is => 'ro', isa => 'Str', required => 1 );
has create_chk_ids => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has delete_chk_ids => ( is => 'ro', isa => 'ArrayRef', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;

    $self->action_log([ member_id => $member_id, create_count => scalar @{$self->create_chk_ids}, delete_count => scalar @{$self->delete_chk_ids} ]);

    for my $id (@{$self->create_chk_ids})   {
        Hirukara::Command::Checklist::Create->new(
            database  => $self->database,
            member_id => $member_id,
            circle_id => $id,
        )->run;
    }

    for my $id (@{$self->delete_chk_ids})   {
        my $ret = Hirukara::Command::Checklist::Delete->new(
            database  => $self->database,
            member_id => $member_id,
            circle_id => $id,
        )->run;
    }
}

1;
