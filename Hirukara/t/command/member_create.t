use utf8;
use strict;
use t::Util;
use Test::More tests => 4;

my $m = create_mock_object;

subtest "member create ok" => sub {
    plan tests => 10;

    output_ok {
        my $ret = $m->run_command('member.create' => {
            id          => '11223344',
            member_id   => 'mogemoge',
            member_name => 'member name',
            image_url   => 'image_url',
        });

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "Hirukara::Database::Row::Member";

    } qr/\[INFO\] メンバーを作成しました。 \(id=11223344, メンバー名=member name\(mogemoge\)\)/;


    my $ret = $m->run_command('member.select' => { member_id => 'mogemoge' });
    ok $ret, "member exist";
    is $ret->id,           '11223344',     'id ok';
    is $ret->member_id,    'mogemoge',     'member_id ok';
    is $ret->member_name,  'member name',  'display_name ok';
    is $ret->image_url,    'image_url',    'image_url ok';

    actionlog_ok $m, { message_id => 'メンバーを作成しました。 (id=11223344, メンバー名=member name(mogemoge))', circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "member already exist" => sub {
    plan tests => 3;

    output_ok {
        my $ret = $m->run_command('member.create' => {
            id          => '11223344',
            member_id   => 'mogemoge',
            member_name => 'member name',
            image_url   => 'image_url',
        });

        ok !$ret, "nothing returned on member exists";

    } qr/\[INFO\] メンバーが存在します。 \(メンバー名=member name\(mogemoge\)\)/;
    delete_actionlog_ok $m, 0;
};


subtest "member update ok" => sub {
    plan tests => 5;

    output_ok { $m->run_command('member.update' => { member_id => 'mogemoge', member_name => 'piyopiyo' }) }
        qr/\[INFO\] メンバーの名前を変更しました。 \(メンバー名=piyopiyo\(mogemoge\), before_name=member name, after_name=piyopiyo\)/;

    my $member = $m->run_command('member.select' => { member_id => 'mogemoge' });
    is $member->member_id,   'mogemoge', 'member_id ok';
    is $member->member_name, 'piyopiyo', 'member_name ok';

    actionlog_ok $m, { message_id => 'メンバーの名前を変更しました。 (メンバー名=piyopiyo(mogemoge), before_name=member name, after_name=piyopiyo)', circle_id => undef };
    delete_actionlog_ok $m, 1;
};


subtest "member not updated" => sub {
    plan tests => 2;

    output_ok { $m->run_command('member.update' => { member_id => 'mogemogemogemoge', member_name => 'piyopiyopiyo' }) }
        qr/\[INFO\] メンバーが存在しません。 \(メンバー名=mogemogemogemoge\)/;
    delete_actionlog_ok $m, 0;
};
