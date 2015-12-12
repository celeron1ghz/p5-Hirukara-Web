use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use Test::Time::At;

my $m = create_mock_object;

subtest "member create ok" => sub_at {
    plan tests => 4;

    my $r1 = $m->run_command('member.create' => {
        id          => '11223344',
        member_id   => 'mogemoge',
        member_name => 'member name',
        image_url   => 'image_url',
    });

    isa_ok $r1, "Hirukara::Database::Row::Member";

    my $r2 = $m->run_command('member.select' => { member_id => 'mogemoge' });
    is_deeply $r2->get_columns, {
        id          => '11223344',
        member_id   => 'mogemoge',
        member_name => 'member name',
        image_url   => 'image_url',
        created_at  => 1234567890,
    };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'mogemoge',
        message_id => 'メンバーを作成しました。 (id=11223344, member_id=mogemoge)',
        parameters => '["メンバーを作成しました。","id","11223344","member_id","mogemoge"]',
    };
} 1234567890;

subtest "member already exist" => sub {
    plan tests => 3;

    my $ret = $m->run_command('member.create' => {
        id          => '11223344',
        member_id   => 'mogemoge',
        member_name => 'member name',
        image_url   => 'image_url',
    });

    ok !$ret, "nothing returned on member exists";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => 'メンバーが存在します。 (exist_member_id=mogemoge)',
        parameters => '["メンバーが存在します。","exist_member_id","mogemoge"]',
    };

};

subtest "member update ok" => sub {
    plan tests => 3;
    $m->run_command('member.update' => { member_id => 'mogemoge', member_name => 'piyopiyo' });

    my $member = $m->run_command('member.select' => { member_id => 'mogemoge' });
    is_deeply $member->get_columns, {
        id          => '11223344',
        member_id   => 'mogemoge',
        member_name => 'piyopiyo',
        image_url   => 'image_url',
        created_at  => 1234567890,
    };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'mogemoge',
        message_id => 'メンバーの名前を変更しました。 (member_id=mogemoge, before_name=member name, after_name=piyopiyo)',
        parameters => '["メンバーの名前を変更しました。","member_id","mogemoge","before_name","member name","after_name","piyopiyo"]',
    };
};

subtest "member not updated" => sub {
    plan tests => 2;
    $m->run_command('member.update' => { member_id => 'mogemogemogemoge', member_name => 'piyopiyopiyo' });

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => 'メンバーが存在しません。 (not_exist_member_id=mogemogemogemoge)',
        parameters => '["メンバーが存在しません。","not_exist_member_id","mogemogemogemoge"]',
    };
};
