package t::Util;
BEGIN {
#    unless ($ENV{PLACK_ENV}) {
#        $ENV{PLACK_ENV} = 'test';
#    }
    if ($ENV{PLACK_ENV} eq 'production') {
        die "Do not run a test script on deployment environment";
    }
}
use File::Spec;
use File::Basename;
use File::Temp;
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));
use parent qw/Exporter/;
use Test::More 0.98;
use Test::Mock::Guard 'mock_guard';
use Test::WWW::Mechanize;
use Plack::Util;
use LWP::Protocol::PSGI;
use Capture::Tiny;

our @EXPORT = qw(
    ua
    slurp
    create_mock_object
    mock_loggin_session
    mock_session
    record_count_ok
    test_actionlog_ok
    test_stdout_ok
    create_file
    delete_cached_log
    result_as_hash_array
    actionlog_ok
    make_temporary_file
    test_reading_csv
    exception_ok

    get_valid_circle_data
    create_mock_circle
);

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

sub ua {
    LWP::Protocol::PSGI->register(Plack::Util::load_psgi 'script/hirukara-server');
    Test::WWW::Mechanize->new(@_);
}

sub slurp {
    my $fname = shift;
    open my $fh, '<:encoding(UTF-8)', $fname or die "$fname: $!";
    scalar do { local $/; <$fh> };
}

sub create_mock_object   {
    use Hirukara;
    use Path::Tiny;
    use File::Slurp;
    use File::Temp;
    use Encode;

    my $t = Hirukara->bootstrap;
    my $db = Path::Tiny->tempdir->child(File::Temp::mktemp("acceptessa.XXXXXX"));
    $db->parent->mkpath;

    ## create empty database
    {
        my $dsn = ["dbi:SQLite:$db", "", "", { sqlite_unicode => 1 }]; 
        local *Hirukara::config = sub { +{ DBI => $dsn, Auth => { Twitter => { consumer_key => "", consumer_secret => ""} } } };
        my $dbh = DBI->connect(@$dsn);
        my @ddls = split ";", File::Slurp::slurp("sql/sqlite.sql");
        $dbh->do($_) for @ddls;
        $t->db; ## call for db object caching
        $t->{__log} = [];
        $t->{__guard} = mock_guard('Hirukara::Web' => +{ db => sub { $t->db } });
        $t->{__guard2} = mock_guard('Log::Minimal' => +{ _log => sub { shift; shift; push @{$t->{__log}}, decode_utf8 sprintf(shift, @_) } });
    }
    $t;
}

sub mock_loggin_session {
    my $data = shift;
    mock_guard('Hirukara::Web' => +{ loggin_user => sub { $data } }); 
}

{
    package Hirukara::MockSession;
    use strict;
    use warnings;
    use Test::Mock::Guard 'mock_guard';
    my $SESSION;
    sub new {
        my($class) = @_; 
        my $guard = mock_guard('Hirukara::Web' => +{ session => sub {
            $SESSION = $_[0]->{session}; ## stolen! :-)
            Hirukara::Web::Plugin::Session::_session(@_); ## call original method
        } }); 
        bless { guard => $guard, session => \$SESSION }, $class;
    }   
    sub session { ${$_[0]->{session}} }
}

sub mock_session { Hirukara::MockSession->new }

sub record_count_ok {
    my $tessa = shift;
    my $data = shift;
    my $result = {}; 

    for my $table (keys %$data) {
        my $cnt = $tessa->db->count($table);
        $result->{$table} = $cnt;
    }   

    is_deeply $result, $data, 'table record count ok';
}

sub test_actionlog_ok {
    my $t = shift;
    is_deeply [map { my $d = $_->get_columns; delete $d->{created_at}; $d } $t->db->search('action_log')->all], [@_], 'actionlog ok';
    is_deeply $t->{__log}, [ map { $_->{message_id} } @_ ], 'stdout ok';
    delete_cached_log($t);
}

sub test_stdout_ok {
    my $t = shift;
    is_deeply $t->{__log}, [@_], 'stdout ok';
    $t->{__log} = []; ## clear after test
}

sub create_file {
    my $content = shift;
    my $f = File::Temp->new;
    print $f $content;
    close $f; 
    return $f; 
}

sub delete_cached_log {
    my $t = shift;
    $t->db->delete('action_log');
    $t->{__log} = []; ## clear after test
}

sub result_as_hash_array {
    my $tessa = shift;
    [ map { $_->get_columns } $tessa->db->search(@_)->all ];
}

## hirukara original
sub actionlog_ok {
    my $h = shift;
    my $ret = $h->run_command('action_log.select');
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
    use Hirukara::Parser::CSV;
    Hirukara::Parser::CSV->read_from_file($file);
}
## hirukara original

sub exception_ok(&@)    {
    my($sub,$clazz,$mess_re) = @_;

    local $@;
    eval { $sub->() };

    my $error = $@;
    isa_ok $error, $clazz;
    like "$error", $mess_re, "exception message is '$mess_re'";
}

# initialize database
#use Hirukara;
#{
#    unlink 'db/test.db' if -f 'db/test.db';
#    system("sqlite3 db/test.db < sql/sqlite.sql");
#}

1;
