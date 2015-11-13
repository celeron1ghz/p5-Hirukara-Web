use strict;
use warnings;
use t::Util;
use Test::More tests => 1;

my $ua = ua max_redirect => 0, cookie_jar => {};
my $t  = mocktessa;

subtest 'not loggeed in test ok' => sub {
    plan tests => 4;
    {
        my $r = $ua->get("http://localhost/");
        is $r->code, 200, "200 /";
        like $r->content, qr/Login via Twitter/, 'contents ok';
    }
    {
        1;
        # TODO: login test
        #my $r = $ua->get("http://localhost/auth/twitter/authenticate");
    }
    {
        my $r = $ua->get("http://localhost/logout");
        is $r->code, 302, "302 /logout";
        is $r->header('Location'), 'http://localhost/', 'redirect url ok';
    }
};
