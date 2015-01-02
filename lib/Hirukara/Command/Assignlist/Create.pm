package Hirukara::Command::Assignlist::Create;
use utf8;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has member_id => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $exhibition = $self->exhibition;
    my $param = {
        name       => "${exhibition} 割り当てリスト",
        member_id  => $self->member_id,
        comiket_no => $exhibition,
    }; 

    my $ret = $self->database->insert(assign_list => $param);

    $self->action_log([ id => $ret->id, name => $ret->name, comiket_no => $exhibition]);
    $ret;
}

1;
