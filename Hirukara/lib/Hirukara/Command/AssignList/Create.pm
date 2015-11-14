package Hirukara::Command::AssignList::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self       = shift;
    my $exhibition = $self->exhibition;
    my $param      = {
        name       => "新規割当リスト",
        comiket_no => $exhibition,
        created_at => time,
    }; 

    my $ret = $self->db->insert(assign_list => $param);
    $self->actioninfo(undef, "割り当てリストを作成しました。", 
        ID         => $ret->id,
        割当名     => $ret->name,
        コミケ番号 => $exhibition,
        メンバーID => $self->member_id,
    );
    $ret;
}

1;
