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

sub checklist_dir {
    use Path::Tiny;
    my $path = path('./checklist');
    $path->mkpath;
    $path;
}

sub condition {
    my $c = shift;
    $c->{condition} //= Hirukara::SearchCondition->new(database => $c->db);
}

sub get_condition_object    {
    my($self,$param) = @_;
    $self->condition->run($param);
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
        hirukara => $self,
        $self->exhibition ? (exhibition => $self->exhibition) : (),
        %{$args || {}},
    };

    $command_class->new(%$param)->run;
}

sub run_command_with_options    {
    my($self,$command) = @_;
    $command or Hirukara::CLI::ClassLoadFailException->throw("Usage: $0 <command name> [<args>...]");
    my $command_class = $self->load_class($command);

    $command_class->new_with_options(hirukara => $self)->run;
}

sub actionlog   {
    my ($c,$color,$mess,@optional) = @_;
    my $log;
    my @attaches;
    my @logstr;
    my @orig;
    my $circle;

    while (my($k,$v) = splice @optional, 0, 2)   {
        if ($k eq 'circle') {
            $circle = $v;
            push @orig, circle_id => $v->id;
        } else {
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
        message_id => "$log$joined",
        parameters => decode_utf8( encode_json([$mess,@orig]) ),
        created_at => $now,
    });

=for

    my $host = $c->can('req') ? $c->req->headers->header('Host') : $ENV{HOSTNAME};
    if (!exists $c->{slack}) {
        my $conf    = $c->config->{Slack} or return;
        my $channel = $conf->{channel}    or die "Missing configuration Slack.channel";
        my $token   = $conf->{token}      or die "Missing configuration Slack.token";
        $c->{slack}         = WebService::Slack::WebApi->new(token => $token);
        $c->{slack_channel} = $channel;
    }

    ## logging to slack
    my $thumb = $c->can('loggin_user') ? $c->loggin_user->{profile_image_url} : undef;
    $c->{slack}->chat->post_message(
        icon_emoji => ':tessa:',
        username => "Acceptessa Notifier ($host)",
        channel  => $c->{slack_channel},
        attachments => [
            {   
                color     => $color,
                thumb_url => $thumb,
                mrkdwn_in => ['fields'],
                title     => $mess,
                fields    => \@attaches,
            }   
        ], 
    );

=cut

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

