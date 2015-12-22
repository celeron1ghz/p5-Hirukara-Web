package Hirukara::Command::CircleType::Update;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has id        => ( is => 'ro', isa => 'Str', required => 1 );
has type_name => ( is => 'ro', isa => 'Str', required => 1 );
has comment   => ( is => 'ro', isa => 'Str' );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $type = $self->db->single(circle_type => { id => $self->id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'circle_type', id => $self->id);

    $self->db->update($type, { type_name => $self->type_name, comment => $self->comment });

    $self->actioninfo("サークル属性を更新しました。" =>
        id => $self->id, name => $self->type_name, comment => $self->comment, member_id => $self->member_id);
    $type;
}

1;
