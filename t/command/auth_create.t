use strict;
use t::Util;
use Test::More tests => 3;
use_ok 'Hirukara::Command::Auth::Create';

my $m = create_mock_object;

subtest "auth create ok" => sub {
    output_ok {
        my $ret = Hirukara::Command::Auth::Create->new(database => $m->database, member_id => 'mogemoge', role_type => 'fugafuga')->run;
        ok $ret, "object returned on auth create ok";
        isa_ok $ret, "Hirukara::Database::Row::MemberRole";

    } qr/\[INFO\] AUTH_CREATE: id=1, member_id=mogemoge, role=fugafuga/;

    my $ret = $m->database->single(member_role => { id => 1 });
    ok $ret, "row exist";
    is $ret->member_id, 'mogemoge', 'member_id ok';
    is $ret->role_type, 'fugafuga', 'role_type ok';
};


subtest "auth already exist" => sub {
    output_ok {
        my $ret = Hirukara::Command::Auth::Create->new(database => $m->database, member_id => 'mogemoge', role_type => 'fugafuga')->run;
        ok !$ret, "nothing returned on auth exists";

    } qr/\[INFO\] AUTH_EXISTS: member_id=mogemoge, role=fugafuga/;

    my $ret = $m->database->single(member_role => { id => 1 });
    ok $ret, "row exist";
    is $ret->member_id, 'mogemoge', 'member_id ok';
    is $ret->role_type, 'fugafuga', 'role_type ok';
};

