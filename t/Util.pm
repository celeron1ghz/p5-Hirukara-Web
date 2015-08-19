package t::Util;
use strict;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
}
use parent qw/Exporter/;
use Test::More 0.96;
use File::Temp;

use Encode;
use Hirukara;
use Hirukara::Database;
use Hirukara::Parser::CSV;
use File::Slurp();
use Capture::Tiny();
use Path::Tiny;
use Plack::Util;

our @EXPORT = qw/
    create_mock_object
    output_ok
    supress_log
    actionlog_ok
    make_temporary_file
    test_reading_csv
    exception_ok
    create_object_mock
    delete_actionlog_ok 
/;

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
    my $ret = $h->run_command('actionlog_select');
    my $logs = [ map { $_->get_columns } @{$ret->{actionlogs}} ];
    delete $_->{created_at} for @$logs;
    delete $_->{id}         for @$logs;
    delete $_->{parameters} for @$logs;
    is_deeply $logs, \@_, "actionlog structure ok";
}

sub make_temporary_file {
    my $val = shift;
    my($fh,$filename) = File::Temp::tempfile();
    print $fh encode_utf8 $val;
    close $fh;
    return $filename;
}

sub test_reading_csv {
    my($content) = @_; 
    my $file = make_temporary_file($content);
    Hirukara::Parser::CSV->read_from_file($file);
}

sub exception_ok(&@)    {
    my($sub,$clazz,$mess_re) = @_;

    local $@;
    eval { $sub->() };

    my $error = $@;
    isa_ok $error, $clazz;
    like "$error", $mess_re, "exception message is '$mess_re'";
}

sub create_object_mock    {
    my($args) = @_; 
    my $param = {}; 

    while ( my($key,$val) = each %$args )  {
        $param->{$key} = sub { $val };
    }   

    Plack::Util::inline_object(%$param);
}

sub delete_actionlog_ok {
    my $m = shift;
    my $count = shift;
    is $m->database->delete('action_log'), $count, "action_log deleted $count";
}

1;
