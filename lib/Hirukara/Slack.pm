package Hirukara::Slack;
use utf8;
use Moose;
use Encode;
use WebService::Slack::WebApi;

has token        => ( is => 'ro', isa => 'Str', required => 1 );
has post_channel => ( is => 'ro', isa => 'Str', required => 1 );
has reply_user   => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );

has username     => ( is => 'ro', isa => 'Str', default => 'Hirukara Notifier' );
has icon_emoji   => ( is => 'ro', isa => 'Str', default => ':hirukara:' );

has slack => ( is => 'ro', isa => 'WebService::Slack::WebApi', default => sub {
    my $s = shift;
    WebService::Slack::WebApi->new(token => $s->token);
});

sub BUILD {
    my $self = shift;
    my $channels = $self->slack->channels->list->{channels};
    $self->{_channels} = { map { $_->{name} => $_ } @$channels };
}

sub get_channel_id  {
    my $self = shift;
    my $channel = $self->{_channels}->{$self->post_channel} or die;
    $channel->{id};
}

sub post    {
    my($self,$title,$text) = @_;
    $self->slack->chat->post_message(
        channel     => $self->get_channel_id,
        username    => $self->username,
        icon_emoji  => $self->icon_emoji,
        attachments => [
            {
                color => 'good',
                text  => $text,
                title => $title,
            },
        ],
    );
}

sub upload {
    my $self = shift;
    my $mess = sprintf '%s ファイルのアップロードが完了したよ！！', join ' ' => map { "\@$_" } @{$self->reply_user};
    $self->slack->files->upload(
        channels => [$self->get_channel_id],
        initial_comment => encode_utf8($mess),
        @_,
    );
}

1;
