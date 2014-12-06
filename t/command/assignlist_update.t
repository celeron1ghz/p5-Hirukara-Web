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
        comiket_no => 'mogefuga',
    )->run;
};


subtest "assign_list value ok" => sub {
    my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run;
    ok $ret, "member exist";
    is $ret->id,                '1',              'id ok';
    is decode_utf8($ret->name), '新規作成リスト', 'name ok';
    is $ret->member_id,         undef,            'comiket_no ok';
    is $ret->comiket_no,        'mogefuga',       'comiket_no ok';
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
    } qr/\[INFO\] UPDATE_ASSIGN_MEMBER: assign_id=1, updated_by=mogemoge, before_member=, updated_name=fugafuga/
     ,qr/\[INFO\] UPDATE_ASSIGN_NAME: assign_id=1, updated_by=mogemoge, before_name=/;

    ok my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run, "assign_list ok";
    is $ret->member_id,         'fugafuga',     'member_id ok';
    is decode_utf8($ret->name), 'assign name1', 'name ok';
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
    } qr/\[INFO\] UPDATE_ASSIGN_MEMBER: assign_id=1, updated_by=mogemoge, before_member=fugafuga, updated_name=1122334455/;

    ok my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run, "assign_list ok";
    is $ret->member_id,         '1122334455',     'member_id ok';
    is decode_utf8($ret->name), 'assign name1', 'name ok';
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
    } qr/\[INFO\] UPDATE_ASSIGN_NAME: assign_id=1, updated_by=mogemoge, before_name=assign name1, updated_name=5566778899/;

    ok my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run, "assign_list ok";
    is $ret->member_id,         '1122334455',     'member_id ok';
    is decode_utf8($ret->name), '5566778899', 'name ok';
};
