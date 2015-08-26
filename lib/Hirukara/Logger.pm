package Hirukara::Logger;
use utf8;
use Moose;
use Encode;
use Log::Minimal;
use JSON;
use WebService::Slack::WebApi;

has slack    => ( is => 'rw', isa => 'WebService::Slack::WebApi' );
has database => ( is => 'rw', isa => 'Hirukara::Database', required => 1 );

my $REPLACE = {
    circle_id => sub {
        my($self,$val) = @_;
        my $c = $self->database->single(circle => { id => $val });
        "サークル名" => $c
            ? (sprintf "%s (%s)", $c->circle_name, $c->circle_author)
            : (sprintf "UNKNOWN(%s)", $val)
    },

    member_id => sub {
        my($self,$val) = @_;
        my $m = $self->database->single(member => { member_id => $val });
        "メンバー名" => $m
            ? (sprintf "%s(%s)", $m->member_name, $m->member_id)
            : $val
    },
};

sub _parse_args {
    my($self,$mess,$args) = @_;
    my @orig = my @args = $args ? @$args : ();
    my @kv;
    my @parsed;

    while ( my($k,$v) = splice @args, 0, 2 )    {
        if (my $meth = $REPLACE->{$k})  {
            my($key,$val) = $meth->($self,$v);
            push @kv, "$key=$val";
            push @parsed, $key, $val;
        }
        else {
            push @kv, "$k=$v";
            push @parsed, $k, $v;
        }
    }

    my $param = @kv ? join(", " => @kv) : undef;
    my $text  = defined $param ? sprintf "%s (%s)", $mess || '', $param || '' : sprintf "%s", $mess || '';

    +{
        mess_body  => $mess,
        mess_param => $param,
        mess       => $text,
        param      => \@parsed,
        param_orig => \@orig,
    };
}

sub info {
    my $self   = shift;
    my $parsed = $self->_parse_args(@_);
    infof "%s", map { utf8::is_utf8($_) ? encode_utf8($_ || "") : ($_ || "") } $parsed->{mess};
}

sub ainfo {
    my $self = shift;
    $self->info(@_);
    my $parsed = $self->_parse_args(@_);
    my $mess   = $parsed->{mess};
    my $orig   = $parsed->{param_orig};
    my $args   = $parsed->{param};
    my %args   = @$args;

    $self->post_to_slack($mess,$args);
    $self->database->insert(action_log => {
        message_id => "$mess",
        circle_id  => $args{circle_id} || undef,
        parameters => decode_utf8 encode_json([$parsed->{mess_body}, @$orig]),
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
