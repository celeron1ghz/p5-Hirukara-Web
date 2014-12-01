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

use Path::Tiny;
use Hirukara::Database;
use File::Slurp();
use Capture::Tiny 'capture_merged';

our @EXPORT = qw/create_mock_object insert_data create_model_mock capture_merged/;

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

sub insert_data {
    my($self,$data) = @_;
    while ( my($table,$d) = each %$data ) {
        for my $row (@$d)    {
            $self->database->insert($table => $row);
        }
    }
}

sub create_mock_object   {
    my $class = shift;
    my $conf = $class->load_config;

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


sub create_model_mock   {
    my($class) = @_;
    my $h = t::Util->create_mock_object;
    my $o = $class->new(
        c => t::Util::ModelMock->new({ database => $h->database }),
    );
    $o;
}

1;
