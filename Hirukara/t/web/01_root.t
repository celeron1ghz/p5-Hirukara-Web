use utf8;
use strict;
use warnings;
use t::Util;
use Test::More tests => 5;
use Encode;

my $ua = ua max_redirect => 0, cookie_jar => {};
my $t  = create_mock_object;

{
    my $r1 = $ua->get('http://localhost/');
    is $r1->code, 200, '200 /';
    like decode_utf8($r1->content), qr!<title>\[Hirukara\] ログイン \(\)</title>!, 'login page';
    like decode_utf8($r1->content), qr/Login via Twitter/, 'login page';
}
{
    my $guard = mock_loggin_session +{ member_id => 'mogemoge' };
    my $r1 = $ua->get('http://localhost/');
    is $r1->code, 200, '200 /';
    like decode_utf8($r1->content), qr!<title>\[Hirukara\] トップページ \(\)</title>!, 'top page';
}
