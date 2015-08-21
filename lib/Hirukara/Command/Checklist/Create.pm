package Hirukara::Command::Checklist::Create;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $member_id = $self->member_id;
    my $circle_id = $self->circle_id;
    my $circle    = $self->database->single(circle => { id => $circle_id })
        or Hirukara::Circle::CircleNotFoundException->throw("no such circle id=$circle_id"); 

    $self->database->single(checklist => { member_id => $member_id, circle_id => $circle_id }) and return;

    my $ret = $self->database->insert(checklist => { circle_id => $circle_id, member_id => $member_id, count => 1 }); 
    $self->logger->ainfo("チェックリストを作成しました。",
        [ member_id => $member_id, circle_id => $circle_id, circle_name => $circle->circle_name ]);

    $ret;
}

1;
