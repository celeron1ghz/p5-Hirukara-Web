use utf8;
use strict;
use t::Util;
use Test::More tests => 2;
use Test::Time::At;

my $m = create_mock_object;

subtest "auth create ok" => sub_at {
    plan tests => 4;
    my $r1 = $m->run_command('auth.create' => { member_id => 'mogemoge', role_type => 'fugafuga' });
    isa_ok $r1, "Hirukara::Database::Row";

    my $r2 = $m->db->single(member_role => { id => 1 });
    is_deeply $r2->get_columns, {
        id         => 1,
        member_id  => 'mogemoge',
        role_type  => 'fugafuga',
        created_at => 1234567890,
    };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => '権限を作成しました。 (id=1, member_id=mogemoge, role=fugafuga)',
        parameters => '["権限を作成しました。","id","1","member_id","mogemoge","role","fugafuga"]',
    };
} 1234567890;

subtest "auth already exist" => sub {
    plan tests => 4;

    my $r1 = $m->run_command('auth.create' => { member_id => 'mogemoge', role_type => 'fugafuga' });
    ok !$r1, "nothing returned on auth exists";

    my $r2 = $m->db->single(member_role => { id => 1 });
    is_deeply $r2->get_columns, {
        id         => 1,
        member_id  => 'mogemoge',
        role_type  => 'fugafuga',
        created_at => 1234567890,
    };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => '権限が既に存在します。 (member_id=mogemoge, role=fugafuga)',
        parameters => '["権限が既に存在します。","member_id","mogemoge","role","fugafuga"]',
    };
};
