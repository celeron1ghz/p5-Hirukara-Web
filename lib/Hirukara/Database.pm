package Hirukara::Database;
use 5.014002;
use Mouse v2.4.5;

# FIXME: temporary loading row classes
use Hirukara::Database::Row::Circle;
use Hirukara::Database::Row::Checklist;
use Hirukara::Database::Row::Member;
use Hirukara::Database::Row::AssignList;

extends qw/Aniki/;
with 'Aniki::Plugin::Count', 'Aniki::Plugin::SelectJoined';

sub single  {
    my($self,$table,$where,$opt) = @_;
    $opt ||= {};
    $opt->{limit} = 1;
    $self->select($table,$where,$opt)->first;
}

sub single_by_sql   {
    my $self = shift;
    my $ret = $self->select_by_sql(@_);
    $ret->first;
}

sub search {
    my $self = shift;
    my $ret = $self->select(@_);
    wantarray ? $ret->all : $ret;
}

sub search_by_sql   {
    my $self = shift;
    $self->select_by_sql(@_);
}

__PACKAGE__->setup(
    schema => 'Hirukara::Database::Schema',
    filter => 'Hirukara::Database::Filter',
    result => 'Hirukara::Database::Result',
    row    => 'Hirukara::Database::Row',
);

__PACKAGE__->meta->make_immutable();

