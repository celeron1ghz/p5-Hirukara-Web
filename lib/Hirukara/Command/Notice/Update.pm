package Hirukara::Command::Notice::Update;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );
has text => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret = $self->database->insert(notice => {
        member_id => $self->member_id,
        text      => $self->text,
    }); 

    $self->action_log(id => $ret->id, member_id => $ret->member_id, text_length => length $ret->text);
    $ret;
}

1;
