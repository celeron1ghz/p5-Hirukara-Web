package Hirukara;
use strict;
use warnings;
use utf8;
our $VERSION='0.01';
use 5.008001;
use Hirukara::Database;
use Hirukara::Exception;
use Hirukara::SearchCondition;
use Log::Minimal;
use Encode;
use Try::Tiny;

use parent qw/Amon2/;
# Enable project local mode.
__PACKAGE__->make_local_context();

sub db {
    my $c = shift;
    if (!exists $c->{db}) {
        my $conf = $c->config->{DBI} or die "Missing configuration about DBI";
        $c->{db} = Hirukara::Database->new(@$conf, query_builder => 'Aniki::QueryBuilder');
            # on_connect_do => [
            #     'SET SESSION sql_mode=STRICT_TRANS_TABLES;',
            # ],
    }
    $c->{db};
}

sub exhibition {
    my $c = shift;
    $c->{exhibition} //= $c->config->{exhibition};
}

sub login {
    my $c = shift;
    my $method = $c->config->{auth_method} || 'restricted';
    my $clazz  = "login.$method";
    $c->run_command($clazz => @_);
}

sub condition {
    my $c = shift;
    $c->{condition} //= Hirukara::SearchCondition->new(database => $c->db);
}

use SQL::QueryMaker;

sub get_condition_object    {
    my($self,$param) = @_;
    $param->{unordered} ||= 0;
    my $cond = $self->condition->run($param);

    if ( $cond->{condition} )   {
        $cond->{condition} = sql_and([ $cond->{condition}, sql_eq('circle.comiket_no', $self->exhibition) ]); 
    } else {
        $cond->{condition} = sql_eq('circle.comiket_no', $self->exhibition);
    }

    $cond;
}

## class loading utilities
use Module::Load();
use String::CamelCase 'camelize', 'decamelize';

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
        Hirukara::CLI::ClassLoadFailException->throw("args is empty");
    }

    my $command_class      = $class->to_class_name($type);
    my($is_success,$error) = Class::Load::try_load_class($command_class);

    unless ($is_success)    {   
        Hirukara::CLI::ClassLoadFailException->throw("Error on loading '$type' ($error)");
    }   

    unless ($command_class->can('does') && $command_class->does('Hirukara::Command'))  {
        Hirukara::CLI::ClassLoadFailException->throw("Error on loading '$type' ($command_class is not a command class)");
    }

    $command_class;
}

sub handle_exception    {
    my($self,$e) = @_;

    if (Hirukara::Exception->caught($e))    {
        $e->rethrow;
    } elsif ($e && $e->isa('Moose::Exception::AttributeIsRequired')) {
        my $name = $e->attribute_name;
        Hirukara::ValidateException->throw("パラメータ '$name' が未指定です。");
    } else {
        Hirukara::RuntimeException->throw(cause => $e);
    }
}

sub run_command {
    my($self,$command,$args) = @_;
    my $command_class = $self->load_class($command);

    my $param = {
        hirukara => $self,
        $self->exhibition ? (exhibition => $self->exhibition) : (),
        %{$args || {}},
    };

    try {
        $command_class->new(%$param)->run;
    } catch {
        $self->handle_exception($_);
    };
}

sub run_command_with_options    {
    my($self,$command) = @_;
    $command or Hirukara::CLI::ClassLoadFailException->throw("Usage: $0 <command name> [<args>...]");
    my $command_class = $self->load_class($command);

    try {
        $command_class->new_with_options(hirukara => $self)->run;
    } catch {
        $self->handle_exception($_);
    };
}

sub actionlog   {
    my ($c,$color,$mess,@optional) = @_;
    my $log;
    my @attaches;
    my @logstr;
    my @orig;
    my $circle;
    my $member_id;

    while (my($k,$v) = splice @optional, 0, 2)   {
        if ($k eq 'circle') {
            $circle = $v;
            push @orig, circle_id => $v->id;
        } else {
            $member_id = $v if $k eq 'member_id';

            push @attaches, { title => $k, value => $v };
            push @logstr,   sprintf "%s=%s", $k || '', $v || '';
            push @orig, $k, $v;
        }
    }

    if ($circle)    {
        my $circle_str = sprintf "[%s] %s / %s", $circle->comiket_no, $circle->circle_name, $circle->circle_author;
        unshift @attaches, { title => 'サークル名', value => $circle_str },
        $log = "$mess: $circle_str";
    } else {
        $log = $mess;
    }

    ## logging to console
use JSON;
    my $now    = time;
    my $joined = @logstr ? sprintf " (%s)", join ", " => @logstr : "";
    infof "%s%s", map { encode_utf8 $_ } $log, $joined;

    $c->db->insert(action_log => {
        circle_id  => $circle ? $circle->id : undef,
        member_id  => $member_id,
        message_id => "$log$joined",
        parameters => decode_utf8( encode_json([$mess,@orig]) ),
        created_at => $now,
    });
}

sub actioninfo  { my $c = shift; $c->actionlog('good',@_) }
sub actionwarn  { my $c = shift; $c->actionlog('warning',@_) }

1;

__END__

=head1 NAME

Hirukara - Hirukara

=head1 DESCRIPTION

This is a main context class for Hirukara

=head1 AUTHOR

Hirukara authors.

