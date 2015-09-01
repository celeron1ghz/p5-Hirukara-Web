use strict;
use Test::WWW::Mechanize::PSGI;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi("app.psgi");
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);

my @get = (
    "/view",
    "/view/me",
    "/circle/moge",
    "/export/excel",
    "/export/checklist",
    "/log",
    "/assign",
    "/assign/view",
    "/mypage",
    "/result",
);

my @post = (
    "/upload",
    "/checklist/add",
);

plan tests => (@get + @post) * 2;

for my $uri (@get) {
    my $res = $mech->get($uri);
    is $res->code, 200, "response ok on $uri";
    is $res->request->url, 'http://localhost/', 'redirected';
}

for my $uri (@post) {

    my $res = $mech->post($uri);
    is $res->code, 403, "response ok on $uri";
    $mech->content_like(qr/Session validation failed/)
}
