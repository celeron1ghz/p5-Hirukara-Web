use utf8;
use strict;
use t::Util;
use Test::More tests => 6;
use_ok 'Hirukara::Command::Member::Create';
use_ok 'Hirukara::Command::Member::Select';
use_ok 'Hirukara::Command::Member::Update';

my $m = create_mock_object;

subtest "member create ok" => sub {
    output_ok {
        my $ret = Hirukara::Command::Member::Create->new(
            database => $m->database,
            id          => '11223344',
            member_id   => 'mogemoge',
            member_name => 'member name',
            image_url   => 'image_url',
        )->run;

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "Hirukara::Database::Row::Member";

    } qr/\[INFO\] MEMBER_CREATE: id=11223344, member_id=mogemoge/;


    my $ret = Hirukara::Command::Member::Select->new(database => $m->database, member_id => 'mogemoge')->run;
    ok $ret, "member exist";
    is $ret->id,           '11223344',     'id ok';
    is $ret->member_id,    'mogemoge',     'member_id ok';
    is $ret->member_name,  'member name',  'display_name ok';
    is $ret->image_url,    'image_url',    'image_url ok';

    actionlog_ok $m, { type => 'メンバーの新規ログイン', message => 'mogemoge さんが初めてログインしました' };
};


subtest "member already exist" => sub {
    output_ok {
        my $ret = Hirukara::Command::Member::Create->new(
            database => $m->database,
            id          => '11223344',
            member_id   => 'mogemoge',
            member_name => 'member name',
            image_url   => 'image_url',
        )->run;

        ok !$ret, "nothing returned on member exists";

    } qr/\[INFO\] MEMBER_EXISTS: member_id=mogemoge/;

    actionlog_ok $m, { type => 'メンバーの新規ログイン', message => 'mogemoge さんが初めてログインしました' };
};


subtest "member update ok" => sub {
    output_ok {
        my $ret = Hirukara::Command::Member::Update->new(
            database => $m->database,
            member_id   => 'mogemoge',
            member_name => 'piyopiyo',
        )->run;

    } qr/\[INFO\] MEMBER_UPDATE: member_id=mogemoge, before_name=member name, after_name=piyopiyo/;

    my $member = Hirukara::Command::Member::Select->new(
        database => $m->database,
        member_id   => 'mogemoge',
    )->run;

    is $member->member_id,   'mogemoge', 'member_id ok';
    is $member->member_name, 'piyopiyo', 'member_name ok';

    actionlog_ok $m
        , { type => 'メンバーの情報変更', message => 'mogemoge さんの表示名を変更しました。(変更前=member name,変更後=piyopiyo)' }
        , { type => 'メンバーの新規ログイン', message => 'mogemoge さんが初めてログインしました' };
};
