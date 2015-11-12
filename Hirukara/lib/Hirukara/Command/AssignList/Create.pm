package Hirukara::Command::AssignList::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $exhibition = $self->exhibition;
    my $param = {
        name       => "新規割当リスト",
        comiket_no => $exhibition,
    }; 

    my $ret = $self->database->insert(assign_list => $param);
    $self->logger->ainfo("割り当てリストを作成しました。", [
        id         => $ret->id,
        name       => $ret->name,
        comiket_no => $exhibition,
        member_id  => $self->member_id,
    ]);
    $ret;
}

1;
