package Hirukara;
use Mouse;
use Hirukara::Database;
use Hirukara::SearchCondition;

use Log::Minimal;
use Smart::Args;
use FindBin;
use Path::Tiny;

has database  => ( is => 'ro', isa => 'Teng', required => 1 );

has exhibition => ( is => 'ro', isa => 'Str|Undef' );
has condition  => ( is => 'ro', isa => 'Hirukara::SearchCondition', default => sub { Hirukara::SearchCondition->new(database => shift->database) });

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

    $self->condition->run($req->parameters);
}

## class loading utilities
use Module::Pluggable::Object;
use Hirukara::Exception;
use Module::Load();

sub get_all_command_object  {
    grep { $_->can('does') && $_->does('Hirukara::Command') }
        Module::Pluggable::Object->new(search_path => 'Hirukara::Command', require => 1)->plugins;
}

sub to_command_name {
    my $class = shift;
    my $val = shift or return;
    $val =~ s/^Hirukara::Command::// or return;
    return join '_', map { lc $_ } split '::', $val,
}

sub to_class_name   {
    my $class = shift;
    my $val = shift or return;
    return join '::', 'Hirukara::Command', map { ucfirst lc $_ } split '_', $val;
}

sub run_command {
    my $self = shift;
    my $command = shift;
    my $args = shift;

    my $command_class = Hirukara->to_class_name($command);
    Module::Load::load $command_class;
    debugf "RUN_COMMAND: command=%s, class=%s", $command, $command_class;

    my $param = {
        database => $self->database,
        $self->exhibition ? (exhibition => $self->exhibition) : (),
        %{$args || {}},
    };

    $command_class->new(%$param)->run;
}

1;
