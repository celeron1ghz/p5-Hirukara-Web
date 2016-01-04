package Hirukara::Command::Notice::Update;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has key       => ( is => 'ro', isa => 'Str' );
has title     => ( is => 'ro', isa => 'Str', required => 1 );
has text      => ( is => 'ro', isa => 'Str', required => 1 );
has run_by    => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $key  = $self->key || time;
    my $ret  = $self->db->insert_and_fetch_row(notice => {
        key        => $key,
        member_id  => $self->run_by,
        title      => $self->title,
        text       => $self->text,
        created_at => time,
    }); 

    my $log_key = $self->key ? "告知を更新しました。" : "告知を作成しました。";
    $self->actioninfo($log_key =>
        id => $ret->id, key => $ret->key, title => $ret->title, text_length => length $ret->text, run_by => $self->run_by);

    $ret;
}

__PACKAGE__->meta->make_immutable;
