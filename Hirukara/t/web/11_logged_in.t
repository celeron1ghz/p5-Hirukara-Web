use utf8;
use strict;
use warnings;
use t::Util;
use Test::More tests => 1;
use Encode;

my $ua = ua max_redirect => 0, cookie_jar => {};
my $t  = mocktessa;

subtest 'loggeed in test ok' => sub {
    my $guard = mock_loggin_session { member_id => 'mogemoge', member_name => 'もげもげ', profile_image_url => 'http://mogemoge.com' };

    my @urls = (
        "http://localhost/",
        "http://localhost/checklist",
        "http://localhost/search",
        "http://localhost/admin/assign",
        "http://localhost/admin/assign/view",
        #"http://localhost/admin/log",
        "http://localhost/admin/notice",
        #"http://localhost/members",
    );

    #like decode_utf8($r->content), qr!現在は<span class="exhibition">ComicMarket\d+</span>のチェックリストを集計しています!, 'contents ok';

    plan tests => @urls * 2;
    for my $url (@urls) {
        my $r = $ua->get($url);
        is $r->code, 200, "200 $url";
        like decode_utf8($r->content), qr!もげもげ \(mogemoge\) <img src="http://mogemoge.com"> <span class="caret"></span>!, 'user info show ok';
    }
};
