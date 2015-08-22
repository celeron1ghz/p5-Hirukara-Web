package Hirukara::Logger;
use utf8;
use Moose;
use Encode;
use Log::Minimal;
use JSON;
use WebService::Slack::WebApi;

has slack    => ( is => 'rw', isa => 'WebService::Slack::WebApi' );
has database => ( is => 'rw', isa => 'Hirukara::Database', required => 1 );

sub info {
    my($self,$mess,$args) = @_;
    my @kv;
    my @args = @$args;

    while ( my($k,$v) = splice @args, 0, 2 )    {
        push @kv, "$k=$v";
    }
    my $param_str = @kv ? sprintf " (%s)", join(", " => @kv) : "";

    infof "%s%s", map { ($_ || "") } $mess, $param_str;
}

sub ainfo {
    my $self = shift;
    $self->info(@_);

    my($mess,$args) = @_;
    my $param = { @{ $args ? $args : [] } };
    $self->post_to_slack($mess,$args);
    $self->database->insert(action_log => {
        message_id => $mess,
        circle_id  => $param->{circle_id} || undef,
        parameters => encode_json($param),
    })
}

sub post_to_slack    {
    my($self,$mess,$args) = @_;
    my @fields;

    if ($self->slack)  {
        if (my $c = delete $args->{circle})    {
            my $url = 'http://hirukara.camelon.info/circle/' . $c->id;
            push @fields, {
                title => 'サークル名',
                value => sprintf "<%s|%s> (%s)"
                    , $url
                    , $c->circle_name
                    , $c->comiket_no
            };
        }

        if (my $m = $args->{member_id})    {
            push @fields, { title => '操作者', value => $m };
        } 
        
        my $ret = $self->slack->chat->post_message({
            channel => '#dev-sandbox',
            attachments => [
                {
                    color => 'good',
                    mrkdwn_in => ['fields'],
                    title => $mess,
                    fields => \@fields,
                }
            ],
        });
    
        debugf "POST_SLACK: result=%s", ddf($ret);
    }
}

1;
