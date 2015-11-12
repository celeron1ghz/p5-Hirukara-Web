package Hirukara::Web;
use strict;
use warnings;
use utf8;
use parent qw/Hirukara Amon2::Web/;
use File::Spec;

use Log::Minimal;
use Net::Twitter::Lite::WithAPIv1_1;

# dispatcher
use Hirukara::Web::Dispatcher;
sub dispatch {
    return (Hirukara::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
                'Web::Auth' => { module => 'Twitter', on_finished => \&_twitter_auth_successed },
    '+Hirukara::Web::Plugin::Session',
);

sub _twitter_auth_successed {
    my($c,$access_token,$access_secret,$user_id,$screen_name) = @_;
    infof "LOGIN_SUCCESS: user_id=%s, screen_name=%s", $user_id, $screen_name;

    my $conf = $c->config->{Auth}->{Twitter};
    my $n = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key    => $conf->{consumer_key},
        consumer_secret => $conf->{consumer_secret},
        ssl             => 1,
    );

    $n->access_token($access_token);
    $n->access_token_secret($access_secret);

    my $me   = $n->verify_credentials;
    my $id   = $me->{id};
    my $name = $me->{name};
    my $image_url = $me->{profile_image_url};
    $image_url =~ s/^http/https/;

    $c->session->set(user => {
        member_id         => $screen_name,
        member_name       => $name,
        id                => $id,
        profile_image_url => $image_url,
    });

    my $ua = $c->req->headers->header('User-Agent');
    my $ip = $c->req->address;
    $c->redirect("/");
}

# setup view
use Hirukara::Web::View;
{
    sub create_view {
        my $view = Hirukara::Web::View->make_instance(__PACKAGE__);
        no warnings 'redefine';
        *Hirukara::Web::create_view = sub { $view }; # Class cache.
        $view
    }
}

sub loggin_user { my $c = shift; $c->session->get("user") }

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

1;
