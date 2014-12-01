package Hirukara::Command::Notice::Update;
use Mouse;
use Log::Minimal;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );
has text => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret = $self->database->insert(notice => {
        member_id => $self->member_id,
        text      => $self->text,
    }); 

    infof "UPDATE_NOTICE: id=%s, member_id=%s, text_length=%s", $ret->id, $ret->member_id, length $ret->text;
    $ret;
}

1;
