use utf8;
use strict;
use t::Util;
use Test::More tests => 7;
use Test::Exception;

my $m = create_mock_object;
my @ID;

subtest "circle create ok" => sub {
    plan tests => 1;
    for (1 .. 5)    {
        my $ret = $m->run_command(circle_create => {
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
        });

        push @ID, $ret->id;
    }

    is $m->database->count("circle"), 5, "circle count ok";
};

subtest "not die at create and delete is empty" => sub {
    plan tests => 2;
    output_ok {
        $m->run_command(checklist_bulkoperation => {
            member_id => 'moge',
            create_chk_ids => [],
            delete_chk_ids => [],
        });
 
    } qr/\[INFO\] サークルの一括追加・一括削除を行います。 \(member_id=moge, create_count=0, delete_count=0\)/;

    actionlog_ok $m;
};

subtest "die on specify not exist circle in create" => sub {
    plan tests => 3;
    output_ok {
        throws_ok {
            $m->run_command(checklist_bulkoperation => {
                member_id => 'moge',
                create_chk_ids => ['aaa'],
                delete_chk_ids => [],
            });
 
        } qr/no such circle id=aaa/, "die on not exist circle";
    } qr/\[INFO\] サークルの一括追加・一括削除を行います。 \(member_id=moge, create_count=1, delete_count=0\)/;

    actionlog_ok $m;
};

subtest "die on specify not exist circle in delete" => sub {
    plan tests => 3;
    output_ok {
        throws_ok {
            $m->run_command(checklist_bulkoperation => {
                member_id => 'moge',
                create_chk_ids => [],
                delete_chk_ids => ['bbb'],
            });
 
        } qr/no such circle id=bbb/, "die on not exist circle";
    } qr/\[INFO\] サークルの一括追加・一括削除を行います。 \(member_id=moge, create_count=0, delete_count=1\)/;

    actionlog_ok $m;
};

subtest "bulk create ok" => sub {
    plan tests => 10;
    is $m->database->count("checklist"), 0, "checklist count ok";
    my $cnt = 0;

    output_ok {
        $m->run_command(checklist_bulkoperation => {
            member_id => 'moge',
            create_chk_ids => [@ID],
            delete_chk_ids => [],
        });
    }   qr/\[INFO\] サークルの一括追加・一括削除を行います。 \(member_id=moge, create_count=5, delete_count=0\)/
      , map { qr/$_/ }
        map { sprintf q/\[INFO\] チェックリストを作成しました。 \(member_id=moge, circle_id=%s, circle_name=circle %s\)/, $_, ++$cnt } @ID;
 
    is $m->database->count("checklist"), 5, "checklist count ok";

    actionlog_ok $m
        , { message_id => 'チェックリストを作成しました。', circle_id => $ID[4] }
        , { message_id => 'チェックリストを作成しました。', circle_id => $ID[3] }
        , { message_id => 'チェックリストを作成しました。', circle_id => $ID[2] }
        , { message_id => 'チェックリストを作成しました。', circle_id => $ID[1] }
        , { message_id => 'チェックリストを作成しました。', circle_id => $ID[0] };
    delete_actionlog_ok $m, 5;
};

subtest "bulk delete ok" => sub {
    plan tests => 7;
    is $m->database->count("checklist"), 5, "checklist count ok";

    output_ok {
        $m->run_command(checklist_bulkoperation => {
            member_id => 'moge',
            create_chk_ids => [],
            delete_chk_ids => [@ID[3,4]],
        });

    } qr/\[INFO\] サークルの一括追加・一括削除を行います。 \(member_id=moge, create_count=0, delete_count=2\)/
     ,qr/\[INFO\] チェックリストを削除しました。 \(circle_id=45a4a52d74c6788c0a06ed2778bb10ee, circle_name=circle 4, member_id=moge, count=1\)/
     ,qr/\[INFO\] チェックリストを削除しました。 \(circle_id=98a249384e5fbbcd1a2788c4fa461f87, circle_name=circle 5, member_id=moge, count=1\)/;
 
    is $m->database->count("checklist"), 3, "checklist count ok";

    actionlog_ok $m
        , { message_id => "チェックリストを削除しました。", circle_id => '98a249384e5fbbcd1a2788c4fa461f87' }
        , { message_id => "チェックリストを削除しました。", circle_id => '45a4a52d74c6788c0a06ed2778bb10ee' };
    delete_actionlog_ok $m, 2;
};

subtest "both bulk create and bulk delete ok" => sub {
    plan tests => 9;
    is $m->database->count("checklist"), 3, "checklist count ok";

    output_ok {
        $m->run_command(checklist_bulkoperation => {
            member_id => 'moge',
            create_chk_ids => [@ID[3,4]],
            delete_chk_ids => [@ID[0,1,2]],
        });
    } qr/\[INFO\] サークルの一括追加・一括削除を行います。 \(member_id=moge, create_count=2, delete_count=3\)/
     #,(map { qr/\[INFO\] CHECKLIST_CREATE: member_id=moge, circle_id=$_/ } @ID[3,4])
     ,qr/\[INFO\] チェックリストを作成しました。 \(member_id=moge, circle_id=45a4a52d74c6788c0a06ed2778bb10ee, circle_name=circle 4\)/
     ,qr/\[INFO\] チェックリストを作成しました。 \(member_id=moge, circle_id=98a249384e5fbbcd1a2788c4fa461f87, circle_name=circle 5\)/
     ,qr/\[INFO\] チェックリストを削除しました。 \(circle_id=50ef491d06540e7d8b0a4f2161101298, circle_name=circle 1, member_id=moge, count=1\)/
     ,qr/\[INFO\] チェックリストを削除しました。 \(circle_id=222fd52fe28550797ee67b2cb5d3dac4, circle_name=circle 2, member_id=moge, count=1\)/
     ,qr/\[INFO\] チェックリストを削除しました。 \(circle_id=cee5735b5beb1d90f3d4363aea645a05, circle_name=circle 3, member_id=moge, count=1\)/;
 
    is $m->database->count("checklist"), 2, "checklist count ok";

    actionlog_ok $m
        , { message_id => "チェックリストを削除しました。", circle_id => 'cee5735b5beb1d90f3d4363aea645a05' }
        , { message_id => "チェックリストを削除しました。", circle_id => '222fd52fe28550797ee67b2cb5d3dac4' }
        , { message_id => "チェックリストを削除しました。", circle_id => '50ef491d06540e7d8b0a4f2161101298' }
        , { message_id => "チェックリストを作成しました。", circle_id => '98a249384e5fbbcd1a2788c4fa461f87' }
        , { message_id => "チェックリストを作成しました。", circle_id => '45a4a52d74c6788c0a06ed2778bb10ee' };
};
