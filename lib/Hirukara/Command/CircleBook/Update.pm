package Hirukara::Command::CircleBook::Update;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id  => ( is => 'ro', isa => 'Str', required => 1 );
has book_id    => ( is => 'ro', isa => 'Str', required => 1 );
has book_name  => ( is => 'ro', isa => 'Str', required => 1 );
has price      => ( is => 'ro', isa => 'Int', required => 1 );
has run_by     => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self   = shift;
    my $id     = $self->circle_id;
    my $book   = $self->db->single(circle_book => { circle_id => $self->circle_id, id => $self->book_id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'circle_book', id => $self->book_id, member_id => $self->run_by);

    my $circle = $book->circle;
    my $cnt = $self->db->update($book,{
        book_name  => $self->book_name,
        price      => $self->price,
    });

    $self->actioninfo("本の情報を更新しました。", 
        circle => $circle, id => $book->id, book_name => $self->book_name, price => $self->price, run_by => $self->run_by);
    $self->db->single(circle_book => { id => $book->id });
}

__PACKAGE__->meta->make_immutable;
