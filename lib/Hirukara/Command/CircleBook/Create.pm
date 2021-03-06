package Hirukara::Command::CircleBook::Create;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id  => ( is => 'ro', isa => 'Str', required => 1 );
has book_name  => ( is => 'ro', isa => 'Str', default => '新刊セット' );
has price      => ( is => 'ro', isa => 'Int', default => 500 );
has comment    => ( is => 'ro', isa => 'Str' );
has run_by     => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self   = shift;
    my $id     = $self->circle_id;
    my $circle = $self->db->single(circle => { id => $id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'circle', id => $id, member_id => $self->run_by);

    my $ret = $self->db->insert_and_fetch_row(circle_book => {
        circle_id  => $self->circle_id,
        book_name  => $self->book_name,
        price      => $self->price,
        comment    => $self->comment,
        created_by => $self->run_by,
        created_at => time,
    });

    $self->actioninfo("本を追加しました。", 
        circle => $circle, id => $ret->id, book_name => $ret->book_name, comment => $ret->comment, run_by => $self->run_by);
    $ret;
}

__PACKAGE__->meta->make_immutable;
