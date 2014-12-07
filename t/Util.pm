package t::Util;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
}
use parent qw/Exporter/;
use Test::More 0.96;
use File::Temp();

use Hirukara;
use Hirukara::Database;
use File::Slurp();
use Capture::Tiny();
use Path::Tiny;

our @EXPORT = qw/create_mock_object output_ok supress_log/;

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
    my $class = shift;
    my $conf = __PACKAGE__->load_config;

    my $db = Path::Tiny->tempdir->child(File::Temp::mktemp("hirukara.XXXXXX"));
    $db->parent->mkpath;
    $conf->{database}->{connect_info} = ["dbi:SQLite:$db", "", "", { sqlite_unicode => 1 }];

    ## create empty database
    my $dbh = DBI->connect(@{$conf->{database}->{connect_info}});
    my $sql = File::Slurp::slurp("CREATE.sql");
    my @ddls = split ";", File::Slurp::slurp("CREATE.sql");
    $dbh->do($_) for @ddls;

    my $h = Hirukara->load($conf);
    return $h;
}

sub load_config {
    do 'config/development.pl';
}

{
    package t::Util::ModelMock;
    use strict;
    sub db { shift->{database} }
    sub new { my($class,$hash) = @_; bless $hash, $class  }
}

sub output_ok(&@)   {
    my $func = shift;
    my $out = Capture::Tiny::capture_merged { &$func };
    like $out, qr/$_/, "output match '$_'" for @_;
}

sub supress_log(&) {
    my $func = shift;
    local $Log::Minimal::LOG_LEVEL = 'NONE';
    &$func;
}

1;
