package Hirukara::Model::Circle;
use Mouse;
use Smart::Args;
use Log::Minimal;
use JSON;

with 'Hirukara::Model';

sub get_circle_by_id    {
    args my $self,
         my $id => { isa => 'Str' };

    $self->database->single(circle => { id => $id });
}

sub update_circle_info  {
    args my $self,
         my $member_id   => { isa => 'Str' },
         my $circle_id   => { isa => 'Str' },
         my $circle_type => { optional => 1, default => "" },
         my $comment     => { optional => 1, default => "" };

    my $circle = $self->get_circle_by_id(id => $circle_id) or return;
    my $comment_updated;
    my $type_updated;
    my $before_circle_type = $circle->circle_type;

    if ($circle_type ne ($circle->circle_type || ''))    {   
        $circle->circle_type($circle_type);
        $type_updated++;

        infof "UPDATE_CIRCLE_TYPE: circle_id=%s, before=%s, after=%s", $circle_id, $before_circle_type, $circle_type;

        my $before = Hirukara::Constants::CircleType::lookup($before_circle_type);
        my $after  = Hirukara::Constants::CircleType::lookup($circle_type);

        $self->__create_action_log(CIRCLE_TYPE_UPDATE => {
            circle_id   => $circle->id,
            circle_name => $circle->circle_name,
            member_id   => $member_id,
            before_type => $before->{label},
            after_type  => $after->{label},
        });
    }   

    if ($comment ne ($circle->comment || ''))   {   
        $circle->comment($comment);
        $comment_updated++;

        infof "UPDATE_CIRCLE_COMMENT: circle_id=%s", $circle_id;

        $self->__create_action_log(CIRCLE_COMMENT_UPDATE => {
            circle_id   => $circle->id,
            circle_name => $circle->circle_name,
            member_id   => $member_id,
        });
    }

    if ($comment_updated or $type_updated)  {
        $circle->update;
        return $circle;
    }
    else {
        return;
    }
}

1;
