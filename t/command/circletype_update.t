use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Test::Exception;
use Test::Time::At;

my $m = create_mock_object;

subtest "create circle_type ok" => sub_at {
    plan tests => 2;
    $m->run_command('circle_type.create' => {
        type_name => 'mogemoge',
        scheme    => 'fuga',
        member_id => 'piyo',
    });

    $m->run_command('circle_type.create' => {
        type_name => 'foofoo',
        scheme    => 'bar',
        member_id => 'piyo',
    });

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'piyo',
        ,
        message_id => 'サークル属性を追加しました。 (id=1, name=mogemoge, scheme=fuga, member_id=piyo)',
        parameters => '["サークル属性を追加しました。","id","1","name","mogemoge","scheme","fuga","member_id","piyo"]',
    }, {
        id         => 2,
        circle_id  => undef,
        member_id  => 'piyo',
        message_id => 'サークル属性を追加しました。 (id=2, name=foofoo, scheme=bar, member_id=piyo)',
        parameters => '["サークル属性を追加しました。","id","2","name","foofoo","scheme","bar","member_id","piyo"]',
    };
} 1234567890;

subtest "error on not exist circle_type" => sub {
    plan tests => 2;
    exception_ok {
        $m->run_command('circle_type.update' => {
            id => 999,
            type_name => '111111',
            comment   => '222222',
            member_id => 'piyo',
        });
    } 'Hirukara::DB::NoSuchRecordException'
        , qr/^データが存在しません。\(table=circle_type, id=999\)/;

};

subtest "error on not exist circle_type" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle_type.update' => {
        id => 2,
        type_name => '111111',
        comment   => '222222',
        member_id => 'piyo',
    });

    isa_ok $ret, 'Hirukara::Database::Row';

    is_deeply $m->db->single(circle_type => { id => 2 })->get_columns, {
        id => $ret->id,
        type_name => '111111',
        scheme    => 'bar',
        comment   => '222222',
        created_at => 1234567890,
    }, "data ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'piyo',
        message_id => 'サークル属性を更新しました。 (id=2, name=111111, comment=222222, member_id=piyo)',
        parameters => '["サークル属性を更新しました。","id","2","name","111111","comment","222222","member_id","piyo"]',
    };
};
