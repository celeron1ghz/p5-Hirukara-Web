package Hirukara::Web;
use strict;
use warnings;
use utf8;
use parent qw/Hirukara Amon2::Web/;
use File::Spec;

use Encode;
use Log::Minimal;
use Net::Twitter::Lite::WithAPIv1_1;
use Try::Tiny;
use Hirukara::Exception;

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

my $ckey    = $ENV{HIRUKARA_TWITTER_CONSUMER_KEY}    or die "env HIRUKARA_TWITTER_CONSUMER_KEY is not set";
my $csecret = $ENV{HIRUKARA_TWITTER_CONSUMER_SECRET} or die "env HIRUKARA_TWITTER_CONSUMER_SECRET is not set";

sub _twitter_auth_successed {
    my($c,$access_token,$access_secret,$user_id,$screen_name) = @_;
    my $n = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key    => $ckey,
        consumer_secret => $csecret,
        ssl             => 1,
    );

    $n->access_token($access_token);
    $n->access_token_secret($access_secret);

    try {
        my $ret = $c->login($n->verify_credentials);
        $c->session->set(user => $ret);
        return $c->redirect("/");
    } catch {
        if (Hirukara::Exception->caught($_))    {
            warnf "%s (%s)", ref $_, encode_utf8 "$_";
            return $c->render('error.tt', { message => $_->message });
        } else {
            die $_;
        }
    };
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

sub login {
    my $c = shift;
    my $method = $ENV{HIRUKARA_AUTH_METHOD} || 'restricted';
    my $clazz  = "login.$method";
    $c->run_command($clazz => @_);
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
        my $role = $c->db->single(member_role => { member_id => $member_id, role_type => 'assign' });

        unless ($role)  {
            $c->render('error.tt', { message => '└(┐┘)┌ﾌﾟｯﾁｯﾊﾟｧだァーーーーーーーーーーーー!!!!!!!（ﾄｩﾙﾛﾛﾃｯﾃﾚｰwwwwwwﾃﾚﾃｯﾃﾃwwwwﾃﾃｰwww）wwwﾄｺｽﾞﾝﾄｺﾄｺｼﾞｮﾝwwwｽﾞｽﾞﾝwwwww（ﾃﾃﾛﾘﾄﾃｯﾃﾛﾃﾃｰwwww）' })
        }   
    }   
});

1;
