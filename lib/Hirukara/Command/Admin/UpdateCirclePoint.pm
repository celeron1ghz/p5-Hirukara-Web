package Hirukara::Command::Admin::UpdateCirclePoint;
use utf8;
use Moose;
use Encode;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command';

has exhibition => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $it = $self->db->search(circle => { comiket_no => $self->exhibition });
    my $all;
    my $changed;
    my $notchange;
    
    for my $c ($it->all)    {
        my $before = $c->circle_point;
        my $after  = $c->recalc_circle_point;
        $all++;
        $before == $after ? $notchange++ : $changed++;
        debugf "[%03d] -> [%03d] %s / %s", map { encode_utf8 $_ } $before, $after, $c->circle_name, $c->circle_author;
    }

    $self->actioninfo("サークルポイントを更新しました。", all => $all, changed => $changed, not_change => $notchange);
}

__PACKAGE__->meta->make_immutable;
