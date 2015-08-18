package Hirukara::Command::Circle::Update;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id   => ( is => 'ro', isa => 'Str', required => 1 );
has circle_id   => ( is => 'ro', isa => 'Str', required => 1 );
has circle_type => ( is => 'ro', isa => 'Str', default => '' );
has comment     => ( is => 'ro', isa => 'Str', default => '' );

sub run {
    my $self = shift;
    my $circle = $self->database->single(circle => { id => $self->circle_id }) or return;

    my $circle_id = $self->circle_id;
    my $member_id = $self->member_id;
    my $comment   = $self->comment;

    if ($self->circle_type ne ($circle->circle_type || ''))    {   
        my $before_circle_type = $circle->circle_type;
        my $after_circle_type  = $self->circle_type;

        $circle->circle_type($after_circle_type);

        my $bf = $self->database->single(circle_type => { id => $before_circle_type });
        my $af = $after_circle_type
            ? ( $self->database->single(circle_type => { id => $after_circle_type  }) or die "no such circle type '$after_circle_type'" )
            : undef;

        $self->action_log(CIRCLE_TYPE_UPDATE => [
            circle_id   => $circle_id,
            circle_name => $circle->circle_name,
            member_id   => $member_id,
            before_type => ($bf ? $bf->type_name : ''),
            after_type  => ($af ? $af->type_name : ''),
        ]);
    }   

    if ($comment ne ($circle->comment || ''))   {   
        $circle->comment($comment);
        $self->action_log(CIRCLE_COMMENT_UPDATE => [ circle_id => $circle_id, circle_name => $circle->circle_name, member_id => $member_id ]);
    }

    if ($circle->is_changed)    {
        $circle->update;
        return $circle;
    }
    else {
        return;
    }
}

1;
