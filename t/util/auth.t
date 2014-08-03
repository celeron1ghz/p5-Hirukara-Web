use strict;
use Hirukara::Auth;
use Test::More tests => 15;
use Test::Exception;

throws_ok { Hirukara::Auth->new } qr/Attribute \(roles\) is required/, "die on no args";
lives_ok  { Hirukara::Auth->new(roles => {}) } "not die on empty hash";

{
    my $h = Hirukara::Auth->new(roles => { admin => ["moge"], viewer => ["fuga"], connect => [] });
    throws_ok { $h->has_role }                      qr/missing mandatory parameter named '\$member_id'/, "die on no member_id";

    throws_ok { $h->has_role(member_id => "moge") }                qr/missing mandatory parameter named '\$role'/,                "die on no role";
    throws_ok { $h->has_role(member_id => undef) }                 qr/'member_id': Validation failed for 'Str' with value undef/, "die on no role";
    throws_ok { $h->has_role(member_id => "moge", role => undef) } qr/'role': Validation failed for 'Str' with value undef/,      "die on no role";
    ok !$h->has_role(member_id => "", role => "");
    ok !$h->has_role(member_id => "moge", role => "");
    ok !$h->has_role(member_id => "", role => "moge");

    ok  $h->has_role(member_id => "moge", role => "admin");
    ok !$h->has_role(member_id => "fuga", role => "admin");

    ok !$h->has_role(member_id => "moge", role => "viewer");
    ok  $h->has_role(member_id => "fuga", role => "viewer");

    ok !$h->has_role(member_id => "moge", role => "connect");
    ok !$h->has_role(member_id => "fuga", role => "connect");
}
