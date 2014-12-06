package Hirukara::Command::Assignlist::Create;
use Mouse;
use Log::Minimal;

with 'MouseX::Getopt', 'Hirukara::Command';

has comiket_no => ( is => 'ro', isa => 'Str', required => 1);

sub run {
    my $self = shift;
    my $param = { name => "新規作成リスト", member_id => undef, comiket_no => $self->comiket_no }; 

    my $ret = $self->database->insert(assign_list => $param);
    infof "ASSIGNLIST_CREATE: id=%s, name=%s, comiket_no=%s", $ret->id, $ret->name, $ret->comiket_no;
    $ret;
}

1;
