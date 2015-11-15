package Hirukara::Command::Checklist::Update;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );
has count     => ( is => 'ro', isa => 'Str' );
has comment   => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $circle_id = $self->circle_id;
    my $member_id = $self->member_id;

    my $circle = $self->db->single(circle => { id => $self->circle_id });
    my $chk = $self->db->single(checklist => {
        circle_id => $circle_id,
        member_id => $member_id,
    }) or return;

    my $before_count  = $chk->count;
    my $after_count   = $self->count;
    my $after_comment = $self->comment;

    if (defined $after_count and $before_count ne $after_count) {
        $chk->count($after_count);
        $self->actioninfo("チェックリストの冊数を更新しました。",
            circle      => $circle,
            member_id   => $member_id,
            before_cnt  => $before_count || 0,
            after_cnt   => $after_count  || 0,
        );
    }

    if (defined $after_comment) {
        $chk->comment($after_comment);
        $self->actioninfo("チェックリストのコメントを更新しました。", circle => $circle, member_id => $member_id);
    }

    if ($chk->is_changed)   {
        $chk->update;
    }

    return 1;
}

1;
