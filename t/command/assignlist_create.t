use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Encode;
use_ok 'Hirukara::Command::Assignlist::Create';
use_ok 'Hirukara::Command::Assignlist::Single';

my $m = create_mock_object;

subtest "assign_list create ok" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assignlist::Create->new(
            database   => $m->database,
            comiket_no => 'mogefuga',
        )->run;

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "Hirukara::Database::Row::AssignList";

    } qr/\[INFO\] ASSIGNLIST_CREATE: id=1, name=/;

    ok !Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 9999)->run, "object not returned";

    my $ret = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run;
    ok $ret, "member exist";
    is $ret->id,                '1',              'id ok';
    is decode_utf8($ret->name), '新規作成リスト', 'name ok';
    is $ret->comiket_no,        'mogefuga',       'comiket_no ok';
};
