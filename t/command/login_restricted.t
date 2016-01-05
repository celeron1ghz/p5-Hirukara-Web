use utf8;
use strict;
use t::Util;
use Test::More tests => 2;
use Test::Time::At;

my $m = create_mock_object;

subtest "error on member is not exist" => sub {
    plan tests => 2;

    exception_ok {
        $m->run_command('login.restricted' => {
            id => 123,
            name => 'name',
            screen_name => 'mogefuga',
            profile_image_url_https => 'http://mogefuga',
        });
    } 'Hirukara::DB::MemberNotInDatabaseException',
      qr/^ﾎﾟﾎﾟﾛﾝｽﾞﾇ\.\.\.ﾎﾟﾎﾟﾛﾝｽﾞﾇ\.\.\.\(mid=mogefuga\)/;
};


subtest "member update ok" => sub_at {
    plan tests => 6;

    $m->run_command('member.create' => { id => 'moge', member_id => 'mogemoge', member_name => 'mogemogemoge', image_url => 'piyo' });
    delete_cached_log $m;
    record_count_ok $m, { member => 1 };

    my $ret = $m->run_command('login.restricted' => {
        id => 123,
        name => 'name mark2',
        screen_name => 'mogemoge',
        profile_image_url_https => 'http://piyopiyo',
    });

    is_deeply $ret, {
        member_id => 'mogemoge',
        member_name => 'mogemogemoge',
        profile_image_url => 'http://piyopiyo',
    }, 'data ok';

    record_count_ok $m, { member => 1 };

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'mogemoge',
        message_id => 'ログインしました。 (method=restricted, member_id=mogemoge, serial=123, name=name mark2)',
        parameters => '["ログインしました。","method","restricted","member_id","mogemoge","serial","123","name","name mark2"]',
    };

    is_deeply $m->db->single('member')->get_columns, {
        id          => 'moge',
        member_id   => 'mogemoge',
        member_name => 'mogemogemoge',
        image_url   => 'http://piyopiyo',
        created_at  => 1234567890,
    }, 'data ok';
} 1234567890;
