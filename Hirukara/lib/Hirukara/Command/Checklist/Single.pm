package Hirukara::Command::Checklist::Single;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;
    my $circle_id = $self->circle_id;

    my $ret = $self->database->single(checklist => { member_id => $member_id, circle_id => $circle_id });
    $ret;
}

1;
