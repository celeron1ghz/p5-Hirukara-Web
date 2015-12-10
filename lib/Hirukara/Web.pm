package Hirukara::Web;
use strict;
use warnings;
use utf8;
use parent qw/Hirukara Amon2::Web/;
use File::Spec;

use Encode;
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

    my $ret = $c->run_command('member.login' => { credential => $n->verify_credentials });
    $c->session->set(user => $ret);
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

sub render  {
    my($c,$tmpl,$args) = @_; 
    $args->{user} = $c->loggin_user;
    $args->{current_exhibition} = $c->exhibition;
    $args->{members}   = [ $c->db->search('member')->all ];
    $args->{constants} = {
        days         => [ 1, 2, 3 ],
        circle_types => [ $c->db->search('circle_type')->all ],
        #areas        => [ Hirukara::Constants::Area->areas ],
    };
    $c->SUPER::render($tmpl,$args);
}

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

__PACKAGE__->add_trigger(BEFORE_DISPATCH => sub {
    my $c = shift;
    my $path = $c->req->path_info;
    return if $path eq '/';
    return $c->redirect('/') unless $c->loggin_user;
});

__PACKAGE__->add_trigger(BEFORE_DISPATCH => sub {
    my $c = shift;
    my $path = $c->req->path_info;

    if ($path =~ m|^/admin/|)   {   
        my $member_id = $c->loggin_user->{member_id};
        my $role = $c->run_command('auth.single' => { member_id => $member_id, role_type => 'assign' }); 

        unless ($role)  {
            $c->create_simple_status_page(403, encode_utf8 "ﾇﾇﾝﾇ");
        }   
    }   
});

1;
