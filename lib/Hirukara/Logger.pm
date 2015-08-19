package Hirukara::Logger;
use utf8;
use Moose;
use Log::Minimal;
use JSON;

#has slack    => ( is => 'rw', isa => 'WebService::Slack::WebApi' );
has database => ( is => 'rw', isa => 'Hirukara::Database', required => 1 );

sub info {
    my $self = shift;
    my $mess = shift;
    my $args = shift;
    my @kv;
    my $param = {};

    while ( my($k,$v) = splice @$args, 0, 2 )    {
        push @kv, "$k=$v";
        $param->{$k} = $v;
    }

    infof "%s (%s)", $mess, join(", " => @kv);
}

sub ainfo {
    my $self = shift;
    my $mess = shift;
    my $args = shift;
    my @kv;
    my $param = {};

    while ( my($k,$v) = splice @$args, 0, 2 )    {
        push @kv, "$k=$v";
        $param->{$k} = $v;
    }

    infof "%s (%s)", $mess, join(", " => @kv);
    $self->database->insert(action_log => {
        message_id => $mess,
        circle_id  => $param->{circle_id} || undef,
        parameters => encode_json($param),
    })
}

=for

sub info    {
    my($self,$mess,$args) = @_;
    my @fields;

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

    infof "POST_SLACK: result=%s", ddf($ret);
}

=cut

1;
