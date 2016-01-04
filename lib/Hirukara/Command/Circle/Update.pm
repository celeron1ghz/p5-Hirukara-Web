package Hirukara::Command::Circle::Update;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id   => ( is => 'ro', isa => 'Str', required => 1 );
has circle_type => ( is => 'ro', isa => 'Str', default => '' );
has comment     => ( is => 'ro', isa => 'Str', default => '' );
has run_by      => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $circle = $self->db->single(circle => { id => $self->circle_id }) or return;

    my $circle_id = $self->circle_id;
    my $run_by    = $self->run_by;
    my $comment   = $self->comment;
    my $updated_value = {};

    if ($self->circle_type ne ($circle->circle_type || ''))    {   
        my $before_circle_type = $circle->circle_type;
        my $after_circle_type  = $self->circle_type;
        $updated_value->{circle_type} = $after_circle_type;

        my $bf = $self->db->single(circle_type => { id => $before_circle_type });
        my $af = $after_circle_type
            ? ( $self->db->single(circle_type => { id => $after_circle_type  }) or die "no such circle type '$after_circle_type'" )
            : undef;

        $self->actioninfo('サークルの属性を更新しました。' =>
            circle      => $circle,
            before_type => ($bf ? $bf->type_name : ''),
            after_type  => ($af ? $af->type_name : ''),
            run_by      => $run_by,
        );
    }   

    if ($comment ne ($circle->comment || ''))   {   
        $updated_value->{comment} = $comment;
        $self->hirukara->actioninfo('サークルのコメントを更新しました。' => circle => $circle, run_by => $run_by);
    }

    if (keys %$updated_value)   {
        $self->db->update($circle, $updated_value);
        return $circle;
    }
    else {
        return;
    }
}

__PACKAGE__->meta->make_immutable;
