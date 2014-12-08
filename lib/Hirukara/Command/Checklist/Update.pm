package Hirukara::Command::Checklist::Update;
use Mouse;
use Log::Minimal;

with 'MouseX::Getopt', 'Hirukara::Command';

has circle_id => ( is => 'ro', isa => 'Str', required => 1 );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );
has count     => ( is => 'ro', isa => 'Str' );
has comment   => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $circle_id = $self->circle_id;
    my $member_id = $self->member_id;

    my $chk = $self->database->single(checklist => {
        circle_id => $circle_id,
        member_id => $member_id,
    }) or return;


    if (my $after_count = $self->count)   {
        my $before_count = $chk->count;
        $chk->count($after_count);
        infof "CHECKLIST_COUNT_UPDATE: circle_id=%s, member_id=%s, before=%s, after=%s", $circle_id, $member_id, $before_count, $after_count;
    }

    if (my $after_comment = $self->comment) {
        $chk->comment($after_comment);
        infof "CHECKLIST_COMMENT_UPDATE: circle_id=%s, member_id=%s", $circle_id, $member_id;
    }

    if ($chk->is_changed)   {
        $chk->update;
    }

=for

        $self->__create_action_log(CHECKLIST_ORDER_COUNT_UPDATE => {
            circle_id       => $check->circle_id,
            circle_name     => $circle->circle_name,
            member_id       => $check->member_id,
            before_cnt      => $before_count,
            after_cnt       => $check->count,
            comment_changed => ($comment_changed ? "NOT_CHANGE" : "CHANGED"),
        });

=cut

    return 1;
}

1;
