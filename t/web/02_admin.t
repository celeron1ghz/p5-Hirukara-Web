use utf8;
use strict;
use warnings;
use t::Util;
use Test::More tests => 3;
use Encode;

my $ua = ua max_redirect => 0, cookie_jar => {};
my $m  = create_mock_object;

my @normal_pages = (
    "http://localhost/search",
    "http://localhost/checklist",
    "http://localhost/members",
);

my @admin_pages = (
    "http://localhost/admin/assign",
    "http://localhost/admin/assign/view",
    "http://localhost/admin/log",
    "http://localhost/admin/notice",
);

subtest "access /admin on not logged in user" => sub {
    plan tests => @normal_pages * 2;
    for my $url (@normal_pages) {
        my $res = $ua->get($url);
        is $res->code, 302, "302 $url";
        is $res->header('Location'), 'http://localhost/', "redirect to /";
    }
};

subtest "access /admin on logged in user without permission" => sub {
    plan tests => @admin_pages * 2;
    my $guard = mock_loggin_session +{ member_id => 'mogemoge', member_name => 'もげもげ', profile_image_url => 'http://mogemoge.com' };

    for my $url (@admin_pages)  {
        my $res = $ua->get($url);
        is $res->code, 403, "403 $url";
        like decode_utf8($res->content), qr!<title>403 ﾇﾇﾝﾇ</title>!, 'cannot access';
    }
};

subtest "access /admin on logged in user with valid permission" => sub {
    plan tests => @admin_pages * 2;
    my $guard = mock_loggin_session +{ member_id => 'mogemoge', member_name => 'もげもげ', profile_image_url => 'http://mogemoge.com' };

    for my $url (@admin_pages)  {
        $m->run_command('auth.create', { member_id => 'mogemoge', role_type => 'assign' });
        my $res = $ua->get($url);
        is $res->code, 200, '200 /';
        like decode_utf8($res->content), qr!もげもげ \(mogemoge\) <img src="http://mogemoge.com"> <span class="caret"></span>!, 'user info show ok';
    }
};
