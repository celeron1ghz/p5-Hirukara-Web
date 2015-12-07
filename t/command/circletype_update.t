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
    });

    $m->run_command('circle_type.create' => {
        type_name => 'foofoo',
        scheme    => 'bar',
    });

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => 'サークルの属性を追加しました。 (name=mogemoge, scheme=fuga)',
        parameters => '["サークルの属性を追加しました。","name","mogemoge","scheme","fuga"]',
    }, {
        id         => 2,
        circle_id  => undef,
        message_id => 'サークルの属性を追加しました。 (name=foofoo, scheme=bar)',
        parameters => '["サークルの属性を追加しました。","name","foofoo","scheme","bar"]',
    };
} 1234567890;

subtest "error on not exist circle_type" => sub {
    plan tests => 1;
    throws_ok {
        $m->run_command('circle_type.update' => {
            id => 999,
            type_name => '111111',
            comment   => '222222',
        });
    } 'Hirukara::DB::NoSuchRecordException';

};

subtest "error on not exist circle_type" => sub {
    plan tests => 2;
    my $ret = $m->run_command('circle_type.update' => {
        id => 2,
        type_name => '111111',
        comment   => '222222',
    });

    isa_ok $ret, 'Hirukara::Database::Row::CircleType';

    is_deeply $m->db->single(circle_type => { id => 2 })->get_columns, {
        id => $ret->id,
        type_name => '111111',
        scheme    => 'bar',
        comment   => '222222',
        created_at => 1234567890,
    }, "data ok";
};
