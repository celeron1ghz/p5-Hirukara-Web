use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use_ok 'Hirukara::Command::Notice::Update';

my $m = create_mock_object;

subtest "notice create ok" => sub {
    output_ok {
        my $ret = Hirukara::Command::Notice::Update->new(database => $m->database, member_id => 'mogemoge', text => 'fugafuga')->run;
        ok $ret, "object returned on auth create ok";
        isa_ok $ret, "Hirukara::Database::Row::Notice";

    } qr/\[INFO\] NOTICE_UPDATE: id=1, member_id=mogemoge, text_length=8/;

    my $ret = $m->database->single(notice => { id => 1 });
    ok $ret, "row exist";
    is $ret->member_id, 'mogemoge', 'member_id ok';
    is $ret->text, 'fugafuga', 'text ok';

    actionlog_ok $m
        , { type => '告知の変更', message => 'mogemoge さんが告知の内容を変更しました。' };
};

subtest "notice create twice ok" => sub {
    output_ok {
        my $ret = Hirukara::Command::Notice::Update->new(database => $m->database, member_id => 'foofoo', text => 'piyopiyopiyo')->run;
        ok $ret, "object returned on auth create ok";
        isa_ok $ret, "Hirukara::Database::Row::Notice";

    } qr/\[INFO\] NOTICE_UPDATE: id=2, member_id=foofoo, text_length=12/;

    my $ret = $m->database->single(notice => { id => 1 });
    ok $ret, "row exist";
    is $ret->member_id, 'mogemoge', 'member_id ok';
    is $ret->text,      'fugafuga', 'text ok';

    my $ret2 = $m->database->single(notice => { id => 2 });
    ok $ret2, "row exist";
    is $ret2->member_id, 'foofoo',       'member_id ok';
    is $ret2->text,      'piyopiyopiyo', 'text ok';

    actionlog_ok $m
        , { type => '告知の変更', message => 'foofoo さんが告知の内容を変更しました。' },
        , { type => '告知の変更', message => 'mogemoge さんが告知の内容を変更しました。' };
};

