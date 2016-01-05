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

## FIXME: monkey patch!
{
use List::MoreUtils qw/uniq pairwise notall/;
use List::UtilsBy qw/partition_by/;
use SQL::QueryMaker;
use Aniki::Schema::Relationship::Fetcher;
no warnings 'redefine';
*Aniki::Schema::Relationship::Fetcher::execute = sub {
    my ($self, $rows, $prefetch) = @_;
    return unless @$rows;

    my $relationship = $self->relationship;
    my $name         = $relationship->name;
    my $table_name   = $relationship->dest_table_name;
    my $has_many     = $relationship->has_many;
    my @src_columns  = @{ $relationship->src_columns  };
    my @dest_columns = @{ $relationship->dest_columns };

    if (@src_columns == 1 and @dest_columns == 1) {
        my $src_column  = $src_columns[0];
        my $dest_column = $dest_columns[0];

        my @related_rows;
        my @ids = uniq grep defined, map { $_->get_column($src_column) } @$rows;


        my $start = 0;
        my $end = 0;
        while (1)   {
            $start = $end;
            $end = $end + 500 >= @ids ? @ids : $end + 500;

            push @related_rows, $self->handler->select($table_name => {
                $dest_column => sql_in([ @ids[$start .. $end] ])
            }, { prefetch => $prefetch })->all;

            last if $end >= @ids;
        }

        my %related_rows_map = partition_by { $_->get_column($dest_column) } @related_rows;
        for my $row (@$rows) {
            my $src_value = $row->get_column($src_column);
            next unless defined $src_value;

            my $related_rows = $related_rows_map{$src_value};
            $row->relay_data->{$name} = $has_many ? $related_rows : $related_rows->[0];
        }

        $self->_execute_inverse(\@related_rows => $rows);
    }
    else {
        # follow slow case...
        my $handler = $self->handler;
        for my $row (@$rows) {
            next if notall { defined $row->get_column($_) } @src_columns;
            my @related_rows = $handler->select($table_name => {
                pairwise { $a => $row->get_column($b) } @dest_columns, @src_columns
            }, { prefetch => $prefetch })->all;
            $row->relay_data->{$name} = $has_many ? \@related_rows : $related_rows[0];
        }
    }
};
}

sub use_strict_query_builder { 0 }

sub single  {
    my($self,$table,$where,$opt) = @_;
    $opt ||= {};
    $opt->{limit} = 1;
    $self->select($table,$where,$opt)->first;
}

sub single_by_id    {
    my($self,$table,$id) = @_;
    $self->single($table => { id => $id });
}

sub circle_by_id    {
    my($self,$cond) = @_;
    $self->single(circle => $cond, { prefetch => [ {'circle_books' => [{'circle_orders' => ['member']}] } ] });
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
    my $prefetch   = [ 'circle_type', { 'checklists' => ['member'] }, { 'assigns' => [ {'assign_list' => ['member']}] }, { circle_books => ['circle_orders'] } ];
    my $opt        = { order_by => 'day, circle_sym, circle_num, circle_flag ' };

    my ($sql, @bind) = $self->query_builder->select($table_name, $columns, $where, $opt);
    $self->select_by_sql($sql, \@bind, {
        table_name => $table_name,
        columns    => $columns,
        prefetch   => $prefetch,
    });
}

sub get_total_price {
    my($self,$comiket_no,$member_id) = @_;
    $self->select_by_sql(<<"    SQL", [$comiket_no, $member_id]);
    SELECT
        circle.day,
        COUNT(DISTINCT circle.id)            AS circle_count,
        SUM(circle_order.count)     AS book_count,
        SUM(circle_book.price * circle_order.count) AS price
    FROM circle
    LEFT JOIN circle_book
        ON circle.id = circle_book.circle_id
    LEFT JOIN circle_order
        ON circle_book.id = circle_order.book_id
    WHERE circle.comiket_no = ?
    AND   circle_order.member_id = ?
    GROUP BY circle.day
    SQL
}

__PACKAGE__->setup(
    schema => 'Hirukara::Database::Schema',
    filter => 'Hirukara::Database::Filter',
    result => 'Hirukara::Database::Result',
    row    => 'Hirukara::Database::Row',
);

__PACKAGE__->meta->make_immutable();

