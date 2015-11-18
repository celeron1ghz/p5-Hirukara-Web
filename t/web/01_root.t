use utf8;
use strict;
use warnings;
use t::Util;
use Encode;
use Test::More tests => 5;
use Test::Mock::Guard;

my $ua = ua max_redirect => 0, cookie_jar => {};
my $guard = mock_guard('Hirukara' => +{ exhibition => sub { 'ComicMarket999' } });

{
    my $r1 = $ua->get('http://localhost/');
    is $r1->code, 200, '200 /';
    like decode_utf8($r1->content), qr!<title>\[Hirukara\] ログイン \(ComicMarket999\)</title>!, 'login page';
    like decode_utf8($r1->content), qr/Login via Twitter/, 'login page';
}
{
    my $guard = mock_loggin_session +{ member_id => 'mogemoge' };
    my $r1 = $ua->get('http://localhost/');
    is $r1->code, 200, '200 /';
    like decode_utf8($r1->content), qr!<title>\[Hirukara\] トップページ \(ComicMarket999\)</title>!, 'top page';
}
