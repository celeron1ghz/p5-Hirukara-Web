use strict;
use t::Util;
use Test::More tests => 13;
use Test::Exception;
use Hirukara::Model::Auth;

my $h = create_model_mock('Hirukara::Model::Auth');

## TODO: insert method
$h->database->insert(member_role => { id => 1, member_id => 'moge', role_type => 'admin' });
$h->database->insert(member_role => { id => 2, member_id => 'fuga', role_type => 'viewer' });

throws_ok { $h->has_role }                                          qr/missing mandatory parameter named '\$member_id'/, "die on no member_id";
throws_ok { $h->has_role(member_id => "moge") }                     qr/missing mandatory parameter named '\$role_type'/,           "die on no role_type";
throws_ok { $h->has_role(member_id => undef) }                      qr/'member_id': Validation failed for 'Str' with value undef/, "die on no role_type";
throws_ok { $h->has_role(member_id => "moge", role_type => undef) } qr/'role_type': Validation failed for 'Str' with value undef/, "die on no role_type";

local $Log::Minimal::LOG_LEVEL = 'NONE';

ok !$h->has_role(member_id => "", role_type => "");
ok !$h->has_role(member_id => "moge", role_type => "");
ok !$h->has_role(member_id => "", role_type => "moge");

ok  $h->has_role(member_id => "moge", role_type => "admin");
ok !$h->has_role(member_id => "fuga", role_type => "admin");

ok !$h->has_role(member_id => "moge", role_type => "viewer");
ok  $h->has_role(member_id => "fuga", role_type => "viewer");

ok !$h->has_role(member_id => "moge", role_type => "connect");
ok !$h->has_role(member_id => "fuga", role_type => "connect");
