package Hirukara::Command::Assignlist::Create;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

sub run {
    my $self = shift;
    my $exhibition = $self->exhibition;
    my $param = { name => "新規作成リスト", member_id => undef, comiket_no => $exhibition }; 

    my $ret = $self->database->insert(assign_list => $param);

    $self->action_log([ id => $ret->id, name => $ret->name, comiket_no => $exhibition]);
    $ret;
}

1;
