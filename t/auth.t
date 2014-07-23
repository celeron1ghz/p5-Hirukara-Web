use strict;
use Test::WWW::Mechanize::PSGI;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi("app.psgi");
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
my @auth = (
    "/view",
    "/view/me",
    "/circle/moge",
    "/upload",
    "/result",
);

plan tests => @auth * 2;

for my $uri (@auth) {
    my $res = $mech->get($uri);
    is $res->code, 403, "response ok on $uri";
    $mech->content_like(qr/Please login/)
}
