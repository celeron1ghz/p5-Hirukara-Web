package Hirukara::Command::CircleOrder::Update;
use utf8;
use Moose;
use Hirukara::Exception;

with 'MooseX::Getopt', 'Hirukara::Command';

has book_id    => ( is => 'ro', isa => 'Str', required => 1 );
has member_id  => ( is => 'ro', isa => 'Str', required => 1 );
has count      => ( is => 'ro', isa => 'Num', required => 1 );
has comment    => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $book = $self->db->single(circle_book => { id => $self->book_id })
        or Hirukara::Circle::CircleNotFoundException->throw(id => $self->book_id);

    my $circle = $book->circle;
    my $cnt    = $self->count;

    if ($cnt == 0)  {
        ## if count is zero, treating as delete
        my $ret = $self->db->delete(circle_order => { book_id => $book->id, member_id => $self->member_id });
        $self->actioninfo("本の発注を削除しました。",
            circle => $circle, id => $book->id, member_id => $self->member_id, deleted => $ret);

    } else {
        ## if count is positive number, treat as create/update
        my $o = $self->db->single(circle_order => { book_id => $book->id, member_id => $self->member_id });
        my $now = time;

        if ($o) {
            my $before = $o->count;
            my $after  = $self->count;
            my $ret = $self->db->update($o, { count => $after, comment => $self->comment, updated_at => $now });

            $self->actioninfo("本の発注を変更しました。",
                circle => $circle, id => $book->id, member_id => $self->member_id, before => $before, after => $after, ret => $ret);

            $self->db->single(circle_order => { id => $o->id });

        } else {
            my $ret = $self->db->insert_and_fetch_row(circle_order => {
                member_id  => $self->member_id,
                book_id    => $self->book_id,
                count      => $self->count,
                comment    => $self->comment,
                created_at => $now,
                updated_at => $now,
            }); 

            $self->actioninfo("本の発注を追加しました。",
                circle => $circle, id => $book->id, member_id => $self->member_id, count => $self->count);

            $ret;
        }
    }
}

1;
