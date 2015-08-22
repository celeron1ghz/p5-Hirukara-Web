use utf8;
use strict;
use t::Util;
use Test::More tests => 2;

my $m = create_mock_object;

subtest "auth create ok" => sub {
    plan tests => 7;

    output_ok {
        my $ret = $m->run_command('auth.create' => { member_id => 'mogemoge', role_type => 'fugafuga' });
        ok $ret, "object returned on auth create ok";
        isa_ok $ret, "Hirukara::Database::Row::MemberRole";

    } qr/\[INFO\] 権限を作成しました。 \(id=1, member_id=mogemoge, role=fugafuga\)/;

    my $ret = $m->database->single(member_role => { id => 1 });
    ok $ret, "row exist";
    is $ret->member_id, 'mogemoge', 'member_id ok';
    is $ret->role_type, 'fugafuga', 'role_type ok';

    actionlog_ok $m;
};


subtest "auth already exist" => sub {
    plan tests => 6;

    output_ok {
        my $ret = $m->run_command('auth.create' => { member_id => 'mogemoge', role_type => 'fugafuga' });
        ok !$ret, "nothing returned on auth exists";

    } qr/\[INFO\] 権限が既に存在します。 \(member_id=mogemoge, role=fugafuga\)/;

    my $ret = $m->database->single(member_role => { id => 1 });
    ok $ret, "row exist";
    is $ret->member_id, 'mogemoge', 'member_id ok';
    is $ret->role_type, 'fugafuga', 'role_type ok';

    actionlog_ok $m;
};

