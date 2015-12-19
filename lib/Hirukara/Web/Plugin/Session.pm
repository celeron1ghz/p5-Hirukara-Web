package Hirukara::Web::Plugin::Session;
use strict;
use warnings;
use utf8;

use Amon2::Util;
use HTTP::Session2::ServerStore;
use Cache::Memcached::Fast;
use Log::Minimal;
use Encode;

sub init {
    my ($class, $c) = @_;

    # Validate XSRF Token.
    $c->add_trigger(
        BEFORE_DISPATCH => sub {
            my ( $c ) = @_;
            if ($c->req->method ne 'GET' && $c->req->method ne 'HEAD') {
                my $token = $c->req->header('X-XSRF-TOKEN') || $c->req->param('XSRF-TOKEN');
                unless ($c->session->validate_xsrf_token($token)) {
                    warnf "XSRF_DETECTED: user_id=%s", $c->loggin_user->{member_id};
                    return $c->create_simple_status_page(
                        403, encode_utf8 '不正な操作が行われました。一旦ログアウトして再度ログインを行ってください。再ログイン後に再度このエラーが表示された場合、管理者に連絡ください。'
                    );
                }
            }
            return;
        },
    );

    Amon2::Util::add_method($c, 'session', \&_session);

    # Inject cookie header after dispatching.
    $c->add_trigger(
        AFTER_DISPATCH => sub {
            my ( $c, $res ) = @_;
            if ($c->{session} && $res->can('cookies')) {
                $c->{session}->finalize_plack_response($res);
            }
            return;
        },
    );
}

# $c->session() accessor.
sub _session {
    my $self = shift;

    if (!exists $self->{session}) {
        $self->{session} = HTTP::Session2::ServerStore->new(
            env => $self->req->env,
            secret => 'k7TaXzfGnrEsvmcr1Eg4NRS6QDOhI_bd',
            get_store => sub {
                Cache::Memcached::Fast->new({ servers => [{ address => 'localhost:11211' }], namespace => 'hirukara_session' }); 
            },
            session_cookie => {
                httponly => 1,
                secure   => 0,
                name     => 'hirukara_session',
                path     => '/',
                expires  => '+1M',
            },
        );
    }
    return $self->{session};
}

1;
__END__

=head1 DESCRIPTION

This module manages session for Hirukara.

