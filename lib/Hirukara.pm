package Hirukara;
use Mouse;
use Hirukara::CLI;
use Hirukara::Database;
use Hirukara::SearchCondition;

use Log::Minimal;
use Smart::Args;
use Module::Load();
use FindBin;
use Path::Tiny;

has exhibition    => ( is => 'ro', isa => 'Str|Undef' );

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

    my $hirukara_conf = $conf->{hirukara} || {};
    my $exhibition = $hirukara_conf->{exhibition};

    my $ret = $class->new({
        database   => $db,
        exhibition => $exhibition,
    }); 

    infof "INIT_DATABASE: dsn=%s", $db->connect_info->[0];
    infof "INIT_EXHIBITION: name=%s", $exhibition || '(empty)';

    $ret;
}

sub get_context_args    {
    my $self = shift;
    my $where = {};

    if ( my $e = $self->exhibition )    {
        $where->{exhibition} = $e;
    }

    return $where;
}

sub get_condition_object    {
    args my $self,
         my $req => { isa => 'Plack::Request' };

    Hirukara::SearchCondition->run($req->parameters);
}

sub run_command {
    my $self = shift;
    my $command = shift;
    my $args = shift;

    my $command_class = Hirukara::CLI::to_class_name($command);
    Module::Load::load $command_class;
    debugf "RUN_COMMAND: command=%s, class=%s", $command, $command_class;

    my $param = { database => $self->database, %{$args || {}} };
    $param->{exhibition} = $self->exhibition if $self->exhibition;

    $command_class->new(%$param)->run;
}

1;
