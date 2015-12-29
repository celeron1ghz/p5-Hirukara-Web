package Hirukara::Command::AssignList::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has run_by => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self  = shift;
    my $e     = $self->hirukara->exhibition;
    my $param = {
        name       => "新規割当リスト",
        comiket_no => $e,
        created_at => time,
    }; 

    my $ret = $self->db->insert_and_fetch_row(assign_list => $param);
    $self->actioninfo("割り当てリストを作成しました。", 
        id         => $ret->id,
        name       => $ret->name,
        comiket_no => $e,
        run_by     => $self->run_by,
    );
    $ret;
}

1;
