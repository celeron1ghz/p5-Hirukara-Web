package Hirukara;
use strict;
use warnings;
use utf8;
our $VERSION='0.01';
use 5.008001;
use Hirukara::DB::Schema;
use Hirukara::DB;
use Hirukara::Exception;

use parent qw/Amon2/;
# Enable project local mode.
__PACKAGE__->make_local_context();

my $schema = Hirukara::DB::Schema->instance;

sub db {
    my $c = shift;
    if (!exists $c->{db}) {
        my $conf = $c->config->{DBI}
            or die "Missing configuration about DBI";
        $c->{db} = Hirukara::DB->new(
            schema       => $schema,
            connect_info => [@$conf],
            # I suggest to enable following lines if you are using mysql.
            # on_connect_do => [
            #     'SET SESSION sql_mode=STRICT_TRANS_TABLES;',
            # ],
        );
    }
    $c->{db};
}

## class loading utilities
use Module::Pluggable::Object;
use Module::Load();
use String::CamelCase 'camelize', 'decamelize';

sub get_all_command_object  {
    grep { $_->can('does') && $_->does('Hirukara::Command') }
        Module::Pluggable::Object->new(search_path => 'Hirukara::Command', require => 1)->plugins;
}

sub to_command_name {
    my $class = shift;
    my $val = shift or return;
    $val =~ s/^Hirukara::Command::// or return;
    return join '.', map { decamelize $_ } split '::', $val,
}

sub to_class_name   {
    my $class = shift;
    my $val = shift or return;
    return join '::', 'Hirukara::Command', map { camelize $_ } split '\.', $val;
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
        logger   => $self->logger,
        $self->exhibition ? (exhibition => $self->exhibition) : (),
        %{$args || {}},
    };

    $command_class->new(%$param)->run;
}

sub run_command_with_options    {
    my($self,$command) = @_;
    my $command_class = $self->load_class($command);

    $command_class->new_with_options(database => $self->database, logger => $self->logger)->run;
}

1;
__END__

=head1 NAME

Hirukara - Hirukara

=head1 DESCRIPTION

This is a main context class for Hirukara

=head1 AUTHOR

Hirukara authors.

