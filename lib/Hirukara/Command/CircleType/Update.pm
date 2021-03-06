package Hirukara::Command::CircleType::Update;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has id        => ( is => 'ro', isa => 'Str', required => 1 );
has type_name => ( is => 'ro', isa => 'Str', required => 1 );
has comment   => ( is => 'ro', isa => 'Str' );
has run_by    => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $type = $self->db->single(circle_type => { id => $self->id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'circle_type', id => $self->id, member_id => $self->run_by);

    $self->db->update($type, { type_name => $self->type_name, comment => $self->comment });

    $self->actioninfo("サークル属性を更新しました。" =>
        id => $self->id, name => $self->type_name, comment => $self->comment, run_by => $self->run_by);
    $type;
}

__PACKAGE__->meta->make_immutable;
