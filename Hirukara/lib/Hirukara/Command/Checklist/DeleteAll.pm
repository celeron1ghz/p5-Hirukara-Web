package Hirukara::Command::Checklist::DeleteAll;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id  => ( is => 'ro', isa => 'Str', required => 1 );
has exhibition => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my($sql,@bind) = $self->hirukara->db->sql_builder->delete(checklist => {
        member_id => $self->member_id,
        circle_id => \["IN (SELECT id FROM circle WHERE comiket_no = ?)", $self->exhibition],
    });

    my $ret = $self->hirukara->db->do($sql, {}, @bind);
    $self->hirukara->actioninfo(undef, "チェックリストを全削除しました。", member_id => $self->member_id, exhibition => $self->exhibition, count => $ret);
    $ret;
}

1;
