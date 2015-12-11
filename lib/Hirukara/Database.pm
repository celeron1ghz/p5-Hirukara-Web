package Hirukara::Database;
use 5.014002;
use Mouse v2.4.5;
use Log::Minimal;

# FIXME: temporary loading row classes
use Hirukara::Database::Row::Circle;
use Hirukara::Database::Row::Checklist;
use Hirukara::Database::Row::Member;
use Hirukara::Database::Row::AssignList;

=cut

use DBIx::QueryLog;
DBIx::QueryLog->threshold(0.01);
DBIx::QueryLog->useqq(1);
DBIx::QueryLog->compact(1);
DBIx::QueryLog->skip_bind(1);

$DBIx::QueryLog::OUTPUT = sub {
    my %params = @_;

    my $cnt = 0;
    my($pkg,$file,$line);
    while(1)    {
        ($pkg,$file,$line) = caller($cnt);
        last unless $pkg;
        last if $pkg =~ /Hirukara::Command/;
        $cnt++;
    }


    warnf "SLOW_QUERY! %s (%s#%s)", $pkg, $file, $line;
    warnf "SLOW_QUERY: $params{message}";
};

=cut

extends qw/Aniki/;
with 'Aniki::Plugin::Count', 'Aniki::Plugin::SelectJoined';

sub use_strict_query_builder { 0 }

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

sub search_all_joined   {
    my($self,$where) = @_;
    my $table_name = 'circle';
    my $table      = $self->schema->get_table($table_name);
    my $columns    = $table->field_names;
    my $prefetch   = [ 'circle_type', { 'checklists' => ['member'] }, { 'assigns' => ['assign_list'] } ];

    my ($sql, @bind) = $self->query_builder->select($table_name, $columns, $where, {});

    $self->select_by_sql($sql, \@bind, {
        table_name => $table_name,
        columns    => $columns,
        prefetch   => $prefetch,
    });
}

__PACKAGE__->setup(
    schema => 'Hirukara::Database::Schema',
    filter => 'Hirukara::Database::Filter',
    result => 'Hirukara::Database::Result',
    row    => 'Hirukara::Database::Row',
);

__PACKAGE__->meta->make_immutable();

