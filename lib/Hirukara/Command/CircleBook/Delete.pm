package Hirukara::Command::CircleBook::Delete;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has circle_id  => ( is => 'ro', isa => 'Str', required => 1 );
has book_id    => ( is => 'ro', isa => 'Str', required => 1 );
has member_id  => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self   = shift;
    my $id     = $self->circle_id;
    my $circle = $self->db->single(circle => { id => $id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'circle', id => $id, member_id => $self->member_id);

    my $book = $self->db->single(circle_book => { id => $self->book_id })
        or Hirukara::DB::NoSuchRecordException->throw(table => 'circle_book', id => $self->book_id, member_id => $self->member_id);

    $book->circle_orders && scalar @{$book->circle_orders}
        and Hirukara::DB::CircleOrderRecordsStillExistsException->throw(book => $book);

    $self->db->delete($book);
    $self->actioninfo("本を削除しました。", 
        circle => $circle, id => $book->id, book_name => $book->book_name, member_id => $self->member_id);
    $book;
}

1;
