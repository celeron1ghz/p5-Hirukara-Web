use utf8;
use strict;
use t::Util;
use Test::More tests => 5;
use Encode;
use Hirukara::Command::Assignlist::Single;
use Hirukara::Command::Assignlist::Create;
use_ok 'Hirukara::Command::Assignlist::Update';

my $m = create_mock_object;

supress_log {
    my $ret = Hirukara::Command::Assignlist::Create->new(
        database   => $m->database,
        exhibition => 'mogefuga',
    )->run;
};


subtest "assign_list value ok" => sub {
    my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run;
    ok $ret, "member exist";
    is $ret->id,                '1',              'id ok';
    is decode_utf8($ret->name), '新規作成リスト', 'name ok';
    is $ret->member_id,         undef,            'comiket_no ok';
    is $ret->comiket_no,        'mogefuga',       'comiket_no ok';

    actionlog_ok $m;
};


subtest "both member_id and name updated" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assignlist::Update->new(
            database         => $m->database,
            assign_id        => 1,
            member_id        => 'mogemoge',
            assign_member_id => 'fugafuga',
            assign_name      => 'assign name1'
        )->run;
    } qr/\[INFO\] ASSIGNLIST_MEMBER_UPDATE: assign_id=1, member_id=mogemoge, before_member=, after_member=fugafuga/
     ,qr/\[INFO\] ASSIGNLIST_NAME_UPDATE: assign_id=1, member_id=mogemoge, before_name=新規作成リスト, after_name=assign name1/;

    ok my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run, "assign_list ok";
    is $ret->member_id,         'fugafuga',     'member_id ok';
    is decode_utf8($ret->name), 'assign name1', 'name ok';

    actionlog_ok $m
        , { type => '割り当て名の変更', message => 'mogemoge さんが割り当てID 1 の名前を変更しました。(変更前=新規作成リスト,変更後=assign name1)' }
        , { type => '割り当て担当の変更', message => 'mogemoge さんが割り当てID 1 の割り当て担当を変更しました。(変更前=,変更後=fugafuga)' };
};


subtest "only member_id updated" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assignlist::Update->new(
            database         => $m->database,
            assign_id        => 1,
            member_id        => 'mogemoge',
            assign_member_id => '1122334455',
            assign_name      => 'assign name1'
        )->run;
    } qr/\[INFO\] ASSIGNLIST_MEMBER_UPDATE: assign_id=1, member_id=mogemoge, before_member=fugafuga, after_member=1122334455/;

    ok my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run, "assign_list ok";
    is $ret->member_id,         '1122334455',     'member_id ok';
    is decode_utf8($ret->name), 'assign name1', 'name ok';

    actionlog_ok $m
        , { type => '割り当て担当の変更', message => 'mogemoge さんが割り当てID 1 の割り当て担当を変更しました。(変更前=fugafuga,変更後=1122334455)' }
        , { type => '割り当て名の変更', message => 'mogemoge さんが割り当てID 1 の名前を変更しました。(変更前=新規作成リスト,変更後=assign name1)' }
        , { type => '割り当て担当の変更', message => 'mogemoge さんが割り当てID 1 の割り当て担当を変更しました。(変更前=,変更後=fugafuga)' };
};


subtest "only name updated" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assignlist::Update->new(
            database         => $m->database,
            assign_id        => 1,
            member_id        => 'mogemoge',
            assign_member_id => '1122334455',
            assign_name      => '5566778899'
        )->run;
    } qr/\[INFO\] ASSIGNLIST_NAME_UPDATE: assign_id=1, member_id=mogemoge, before_name=assign name1, after_name=5566778899/;

    ok my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run, "assign_list ok";
    is $ret->member_id,         '1122334455', 'member_id ok';
    is decode_utf8($ret->name), '5566778899', 'name ok';

    actionlog_ok $m
        , { type => '割り当て名の変更', message => 'mogemoge さんが割り当てID 1 の名前を変更しました。(変更前=assign name1,変更後=5566778899)' }
        , { type => '割り当て担当の変更', message => 'mogemoge さんが割り当てID 1 の割り当て担当を変更しました。(変更前=fugafuga,変更後=1122334455)' }
        , { type => '割り当て名の変更', message => 'mogemoge さんが割り当てID 1 の名前を変更しました。(変更前=新規作成リスト,変更後=assign name1)' }
        , { type => '割り当て担当の変更', message => 'mogemoge さんが割り当てID 1 の割り当て担当を変更しました。(変更前=,変更後=fugafuga)' };
};
