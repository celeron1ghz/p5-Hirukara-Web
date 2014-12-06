package Hirukara::Command::Assignlist::Create;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has comiket_no => ( is => 'ro', isa => 'Str', required => 1);

sub run {
    my $self = shift;
    my $param = { name => "新規作成リスト", member_id => undef, comiket_no => $self->comiket_no }; 

    my $ret = $self->database->insert(assign_list => $param);

    $self->action_log(id => $ret->id, name => $ret->name, comiket_no => $ret->comiket_no);
    $ret;
}

1;
