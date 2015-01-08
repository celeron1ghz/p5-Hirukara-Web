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

sub load_class  {
    my($class,$type) = @_;

    unless ($type)  {
        Hirukara::CLI::ClassLoadFailException->throw("No class name specified in args");
    }

    my $command_class      = $class->to_class_name($type);
    my($is_success,$error) = Class::Load::try_load_class($command_class);

    unless ($is_success)    {   
        Hirukara::CLI::ClassLoadFailException->throw("command '$type' load fail. Reason are below:\n----------\n$error\n----------\n");
    }   

    unless ($command_class->can('does') && $command_class->does('Hirukara::Command'))  {
        Hirukara::CLI::ClassLoadFailException->throw("command '$type' is not a command class");
    }

    $command_class;
}

sub run_command {
    my($self,$command,$args) = @_;
    my $command_class = $self->load_class($command);

    my $param = {
        database => $self->database,
        $self->exhibition ? (exhibition => $self->exhibition) : (),
        %{$args || {}},
    };

    $command_class->new(%$param)->run;
}

sub run_command_with_options    {
    my($self,$command) = @_;
    my $command_class = $self->load_class($command);

    $command_class->new_with_options(database => $self->database)->run;
}

1;
