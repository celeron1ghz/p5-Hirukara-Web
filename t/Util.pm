package t::Util;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
}
use parent qw/Exporter/;
use Test::More 0.96;

use Hirukara;
use File::Temp();
use Teng::Schema::Loader;

our @EXPORT = qw/create_mock_object insert_data/;

{
    # utf8 hack.
    binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;
    no warnings 'redefine';
    my $code = \&Test::Builder::child;
    *Test::Builder::child = sub {
        my $builder = $code->(@_);
        binmode $builder->output,         ":utf8";
        binmode $builder->failure_output, ":utf8";
        binmode $builder->todo_output,    ":utf8";
        return $builder;
    };
}

sub create_mock_object   {
    my $temp = File::Temp->new(UNLINK => 0);
    $temp->close;
    unlink $temp->filename;

    my $filename = $temp->filename;
    `sqlite3 $filename < CREATE.sql`;

    my $db = Teng::Schema::Loader->load(connect_info=>["dbi:SQLite:$filename", "", "", { sqlite_unicode => 1 }], namespace => "Moge");
    Hirukara->new(database => $db);
}

sub insert_data {
    my($self,$data) = @_;
    while ( my($table,$d) = each %$data ) {
        for my $row (@$d)    {
            $self->database->insert($table => $row);
        }
    }
}

1;
