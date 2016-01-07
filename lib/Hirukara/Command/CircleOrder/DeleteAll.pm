package Hirukara::Command::CircleOrder::DeleteAll;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id  => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $e    = $self->hirukara->exhibition;
    my $ret = $self->db->delete(circle_order => {
        member_id => $self->member_id,
        book_id => \["IN (SELECT circle_book.id FROM circle JOIN circle_book ON circle.id = circle_book.circle_id WHERE circle.comiket_no = ?)", $e],
    });
    $self->actioninfo("発注を全削除しました。", member_id => $self->member_id, exhibition => $e, count => $ret);
    $ret;
}

__PACKAGE__->meta->make_immutable;
