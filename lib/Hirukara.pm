package Hirukara;
use Mouse;
use Hirukara::Database;
use Hirukara::Util;
use Hirukara::Parser::CSV;
use Hirukara::Export::ComiketCsv;
use Hirukara::Export::Excel;
use Hirukara::Constants::CircleType;

use Log::Minimal;
use JSON;
use Smart::Args;
use Module::Load();
use FindBin;
use Path::Tiny;

has database      => ( is => 'ro', isa => 'Teng', required => 1 );
has checklist_dir => ( is => 'ro', isa => 'Path::Tiny', default => sub {
    my $dir = path("$FindBin::Bin/checklist/");
    $dir->mkpath;
    $dir;
});

sub load    {
    my($class,$conf) = @_; 

    my $db_conf = $conf->{database} or die "key 'database' missing";
    my $db = Hirukara::Database->load($db_conf);

    $class->new({ database => $db }); 
}

sub run_command {
    my $self = shift;
    my $command = shift;
    my $args = shift;

use Hirukara::CLI;
my $command_class = Hirukara::CLI::to_class_name($command);
Module::Load::load $command_class;
$command_class->new(database => $self->database, %$args)->run;
}

### other methods
sub merge_checklist {
    my($self,$csv,$member_id) = @_;

use Hirukara::Command::Checklist::Merge;
my $ret = Hirukara::Command::Checklist::Merge->new(database => $self->database, csv => $csv, member_id => $member_id);

    $self->__create_action_log(CHECKLIST_MERGE => {
        member_id   => $member_id,
        create      => (scalar keys %{$ret->merge_results->{create}}),
        delete      => (scalar keys %{$ret->merge_results->{delete}}),
        exist       => (scalar keys %{$ret->merge_results->{exist}}),
        comiket_no  => $csv->comiket_no,
    });

    $ret;
}

sub parse_csv   {
    my($self,$path) = @_;
    my $ret = Hirukara::Parser::CSV->read_from_file($path);
    $ret;
}

1;
