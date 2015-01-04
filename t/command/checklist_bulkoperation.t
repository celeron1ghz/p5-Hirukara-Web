use utf8;
use strict;
use t::Util;
use Test::More tests => 8;
use Test::Exception;
use Hirukara::Command::Circle::Create;
use_ok "Hirukara::Command::Checklist::Bulkoperation";

my $m = create_mock_object;
my @ID;

subtest "circle create ok" => sub {
    for (1 .. 5)    {
        my $ret = Hirukara::Command::Circle::Create->new(
            database      => $m->database,
            comiket_no    => "aa",
            day           => "bb",
            circle_sym    => "cc",
            circle_num    => "dd",
            circle_flag   => "ee",
            circle_name   => "circle $_",
            circle_author => "author",
            area          => "area",
            circlems      => "circlems",
            url           => "url",
        )->run;

        push @ID, $ret->id;
    }

    is $m->database->count("circle"), 5, "circle count ok";
};

subtest "not die at create and delete is empty" => sub {
    output_ok {
        Hirukara::Command::Checklist::Bulkoperation->new(
            database => $m->database,
            member_id => 'moge',
            create_chk_ids => [],
            delete_chk_ids => [],
        )->run;
 
    } qr/\[INFO\] CHECKLIST_BULKOPERATION: member_id=moge, create_count=0, delete_count=0/;

    actionlog_ok $m;
};

subtest "die on specify not exist circle in create" => sub {
    output_ok {
        throws_ok {
            Hirukara::Command::Checklist::Bulkoperation->new(
                database => $m->database,
                member_id => 'moge',
                create_chk_ids => ['aaa'],
                delete_chk_ids => [],
            )->run;
 
        } qr/no such circle id=aaa/, "die on not exist circle";
    } qr/\[INFO\] CHECKLIST_BULKOPERATION: member_id=moge, create_count=1, delete_count=0/;

    actionlog_ok $m;
};

subtest "die on specify not exist circle in delete" => sub {
    output_ok {
        throws_ok {
            Hirukara::Command::Checklist::Bulkoperation->new(
                database => $m->database,
                member_id => 'moge',
                create_chk_ids => [],
                delete_chk_ids => ['bbb'],
            )->run;
 
        } qr/no such circle id=bbb/, "die on not exist circle";
    } qr/\[INFO\] CHECKLIST_BULKOPERATION: member_id=moge, create_count=0, delete_count=1/;

    actionlog_ok $m;
};

subtest "bulk create ok" => sub {
    is $m->database->count("checklist"), 0, "checklist count ok";

    output_ok {
        Hirukara::Command::Checklist::Bulkoperation->new(
            database => $m->database,
            member_id => 'moge',
            create_chk_ids => [@ID],
            delete_chk_ids => [],
        )->run;
    }   qr/\[INFO\] CHECKLIST_BULKOPERATION: member_id=moge, create_count=5, delete_count=0/
      , map { qr/\[INFO\] CHECKLIST_CREATE: member_id=moge, circle_id=$_/ } @ID;
 
    is $m->database->count("checklist"), 5, "checklist count ok";

    actionlog_ok $m
        , { type => "チェックの追加", message => "moge さんが 'circle 5' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 4' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 3' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 2' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 1' を追加しました" };
};

subtest "bulk delete ok" => sub {
    is $m->database->count("checklist"), 5, "checklist count ok";

    output_ok {
        Hirukara::Command::Checklist::Bulkoperation->new(
            database => $m->database,
            member_id => 'moge',
            create_chk_ids => [],
            delete_chk_ids => [@ID[3,4]],
        )->run;

    } qr/\[INFO\] CHECKLIST_BULKOPERATION: member_id=moge, create_count=0, delete_count=2/
     ,qr/\[INFO\] CHECKLIST_DELETE: circle_id=45a4a52d74c6788c0a06ed2778bb10ee, circle_name=circle 4, member_id=moge, count=1/
     ,qr/\[INFO\] CHECKLIST_DELETE: circle_id=98a249384e5fbbcd1a2788c4fa461f87, circle_name=circle 5, member_id=moge, count=1/;
 
    is $m->database->count("checklist"), 3, "checklist count ok";

    actionlog_ok $m
        , { type => "チェックの削除", message => "moge さんが 'circle 5' を削除しました" }
        , { type => "チェックの削除", message => "moge さんが 'circle 4' を削除しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 5' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 4' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 3' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 2' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 1' を追加しました" };
};

subtest "both bulk create and bulk delete ok" => sub {
    is $m->database->count("checklist"), 3, "checklist count ok";

    output_ok {
        Hirukara::Command::Checklist::Bulkoperation->new(
            database => $m->database,
            member_id => 'moge',
            create_chk_ids => [@ID[3,4]],
            delete_chk_ids => [@ID[0,1,2]],
        )->run;
    } qr/\[INFO\] CHECKLIST_BULKOPERATION: member_id=moge, create_count=2, delete_count=3/
     ,(map { qr/\[INFO\] CHECKLIST_CREATE: member_id=moge, circle_id=$_/ } @ID[3,4])
     ,qr/\[INFO\] CHECKLIST_DELETE: circle_id=50ef491d06540e7d8b0a4f2161101298, circle_name=circle 1, member_id=moge, count=1/
     ,qr/\[INFO\] CHECKLIST_DELETE: circle_id=222fd52fe28550797ee67b2cb5d3dac4, circle_name=circle 2, member_id=moge, count=1/
     ,qr/\[INFO\] CHECKLIST_DELETE: circle_id=cee5735b5beb1d90f3d4363aea645a05, circle_name=circle 3, member_id=moge, count=1/;
 
    is $m->database->count("checklist"), 2, "checklist count ok";

    actionlog_ok $m
        , { type => "チェックの削除", message => "moge さんが 'circle 3' を削除しました" }
        , { type => "チェックの削除", message => "moge さんが 'circle 2' を削除しました" }
        , { type => "チェックの削除", message => "moge さんが 'circle 1' を削除しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 5' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 4' を追加しました" }

        , { type => "チェックの削除", message => "moge さんが 'circle 5' を削除しました" }
        , { type => "チェックの削除", message => "moge さんが 'circle 4' を削除しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 5' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 4' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 3' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 2' を追加しました" }
        , { type => "チェックの追加", message => "moge さんが 'circle 1' を追加しました" };
};
