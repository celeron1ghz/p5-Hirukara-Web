package t::Util;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
}
use parent qw/Exporter/;
use Test::More 0.96;
use File::Temp();

use Encode;
use Hirukara;
use Hirukara::Database;
use File::Slurp();
use Capture::Tiny();
use Path::Tiny;

our @EXPORT = qw/create_mock_object output_ok supress_log actionlog_ok/;

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

    my $h;
    supress_log(sub { $h = Hirukara->load($conf) });
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
    my $out = decode_utf8(Capture::Tiny::capture_merged { &$func });

    for my $re (@_)    {
        like $out, $re, "output match '$re'";
    }
}

sub supress_log(&) {
    my $func = shift;
    local $Log::Minimal::LOG_LEVEL = 'NONE';
    &$func;
}

sub actionlog_ok {
    my $h = shift;
    use Hirukara::Command::Actionlog::Select;
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $h->database)->run;
    is_deeply $ret, \@_, "actionlog structure ok";
}

1;
