package Hirukara::Command::CircleBook::Update;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id  => ( is => 'ro', isa => 'Str', required => 1 );
has book_id    => ( is => 'ro', isa => 'Str', required => 1 );
has book_name  => ( is => 'ro', isa => 'Str', required => 1 );
has price      => ( is => 'ro', isa => 'Int', required => 1 );
has updated_by => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self   = shift;
    my $id     = $self->circle_id;
    my $book   = $self->db->single(circle_book => { circle_id => $self->circle_id, id => $self->book_id })
        or Hirukara::Circle::CircleNotFoundException->throw(id => $id);

    my $circle = $book->circle;
    my $cnt = $self->db->update($book,{
        book_name  => $self->book_name,
        price      => $self->price,
    });

    $self->actioninfo("サークルの本の情報を更新しました。", 
        circle => $circle, id => $book->id, book_name => $self->book_name, price => $self->price, member_id => $self->updated_by);
    $self->db->single(circle_book => { id => $book->id });
}

1;
