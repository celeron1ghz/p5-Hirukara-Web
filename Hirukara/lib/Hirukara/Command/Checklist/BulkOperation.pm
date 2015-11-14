package Hirukara::Command::Checklist::BulkOperation;
use utf8;
use Moose;
use Hirukara::Command::Checklist::Create;
use Hirukara::Command::Checklist::Delete;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id      => ( is => 'ro', isa => 'Str', required => 1 );
has create_chk_ids => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has delete_chk_ids => ( is => 'ro', isa => 'ArrayRef', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;

    $self->hirukara->actioninfo(undef,"サークルの一括追加・一括削除を行います。",
        member_id => $member_id, create_count => scalar @{$self->create_chk_ids}, delete_count => scalar @{$self->delete_chk_ids});

    for my $id (@{$self->create_chk_ids})   {
        Hirukara::Command::Checklist::Create->new(
            hirukara  => $self->hirukara,
            database  => $self->database,
            logger    => $self->logger,
            member_id => $member_id,
            circle_id => $id,
        )->run;
    }

    for my $id (@{$self->delete_chk_ids})   {
        my $ret = Hirukara::Command::Checklist::Delete->new(
            hirukara  => $self->hirukara,
            database  => $self->database,
            logger    => $self->logger,
            member_id => $member_id,
            circle_id => $id,
        )->run;
    }
}

1;
