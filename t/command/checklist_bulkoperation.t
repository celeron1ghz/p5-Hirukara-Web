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
        my $ret = create_mock_circle $m, circle_name => "circle $_", circle_author => "author $_";
        push @ID, $ret->id;
    }

    is $m->db->count("circle"), 5, "circle count ok";
    delete_cached_log $m;
};

subtest "not die at create and delete is empty" => sub {
    plan tests => 2;
    $m->run_command('checklist.bulk_operation' => {
        member_id => 'moge',
        create_chk_ids => [],
        delete_chk_ids => [],
    });

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=, delete_count=)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count",0,"delete_count",0]',
    };
};

subtest "die on specify not exist circle in create" => sub {
    plan tests => 4;
    exception_ok {
        $m->run_command('checklist.bulk_operation' => {
            member_id => 'moge',
            create_chk_ids => ['aaa'],
            delete_chk_ids => [],
        });
    } 'Hirukara::DB::NoSuchRecordException', qr/^データが存在しません。\(table=circle, id=aaa, mid=moge\)/;

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=1, delete_count=)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count","1","delete_count",0]',
    };
};

subtest "die on specify not exist circle in delete" => sub {
    plan tests => 4;
    exception_ok {
        $m->run_command('checklist.bulk_operation' => {
            member_id => 'moge',
            create_chk_ids => [],
            delete_chk_ids => ['bbb'],
        });
    } 'Hirukara::DB::NoSuchRecordException', qr/^データが存在しません。\(table=circle, id=bbb, mid=moge\)/;

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=, delete_count=1)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count",0,"delete_count","1"]',
    };
};

subtest "bulk create ok" => sub {
    plan tests => 4;
    is $m->db->count("checklist"), 0, "checklist count ok";
    my $cnt = 5;

    $m->run_command('checklist.bulk_operation' => {
        member_id => 'moge',
        create_chk_ids => [@ID],
        delete_chk_ids => [],
    });

    is $m->db->count("checklist"), 5, "checklist count ok";

    test_actionlog_ok $m, {
        id => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=5, delete_count=)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count","5","delete_count",0]',
    }, {
        id => 2,
        circle_id  => $ID[0],
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle 1 / author 1 (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID[0]","member_id","moge"]!,
    }, {
        id => 3,
        circle_id  => $ID[1],
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle 2 / author 2 (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID[1]","member_id","moge"]!,
    }, {
        id => 4,
        circle_id  => $ID[2],
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle 3 / author 3 (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID[2]","member_id","moge"]!,
    }, {
        id => 5,
        circle_id  => $ID[3],
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle 4 / author 4 (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID[3]","member_id","moge"]!,
    }, {
        id => 6,
        circle_id  => $ID[4],
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle 5 / author 5 (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID[4]","member_id","moge"]!,
    };
};

subtest "bulk delete ok" => sub {
    plan tests => 4;
    is $m->db->count("checklist"), 5, "checklist count ok";

    $m->run_command('checklist.bulk_operation' => {
        member_id => 'moge',
        create_chk_ids => [],
        delete_chk_ids => [@ID[3,4]],
    });

    is $m->db->count("checklist"), 3, "checklist count ok";

    test_actionlog_ok $m, {
        id => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=, delete_count=2)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count",0,"delete_count","2"]',
    }, {
        id => 2,
        circle_id  => $ID[3],
        member_id  => 'moge',
        message_id => 'チェックリストを削除しました。: [ComicMarket999] circle 4 / author 4 (member_id=moge, count=1)',
        parameters => qq!["チェックリストを削除しました。","circle_id","$ID[3]","member_id","moge","count","1"]!,
    }, {
        id => 3,
        circle_id  => $ID[4],
        member_id  => 'moge',
        message_id => 'チェックリストを削除しました。: [ComicMarket999] circle 5 / author 5 (member_id=moge, count=1)',
        parameters => qq!["チェックリストを削除しました。","circle_id","$ID[4]","member_id","moge","count","1"]!,
    };
};

subtest "both bulk create and bulk delete ok" => sub {
    plan tests => 4;
    is $m->db->count("checklist"), 3, "checklist count ok";

    $m->run_command('checklist.bulk_operation' => {
        member_id => 'moge',
        create_chk_ids => [@ID[3,4]],
        delete_chk_ids => [@ID[0,1,2]],
    });
 
    is $m->db->count("checklist"), 2, "checklist count ok";

    test_actionlog_ok $m, {
        id => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=2, delete_count=3)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count","2","delete_count","3"]',
    }, {
        id => 2,
        circle_id  => $ID[3],
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle 4 / author 4 (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID[3]","member_id","moge"]!,
    }, {
        id => 3,
        circle_id  => $ID[4],
        member_id  => 'moge',
        message_id => 'チェックリストを作成しました。: [ComicMarket999] circle 5 / author 5 (member_id=moge)',
        parameters => qq!["チェックリストを作成しました。","circle_id","$ID[4]","member_id","moge"]!,
    }, {
        id => 4,
        circle_id  => $ID[0],
        member_id  => 'moge',
        message_id => 'チェックリストを削除しました。: [ComicMarket999] circle 1 / author 1 (member_id=moge, count=1)',
        parameters => qq!["チェックリストを削除しました。","circle_id","$ID[0]","member_id","moge","count","1"]!,
    }, {
        id => 5,
        circle_id  => $ID[1],
        member_id  => 'moge',
        message_id => 'チェックリストを削除しました。: [ComicMarket999] circle 2 / author 2 (member_id=moge, count=1)',
        parameters => qq!["チェックリストを削除しました。","circle_id","$ID[1]","member_id","moge","count","1"]!,
    }, {
        id => 6,
        circle_id  => $ID[2],
        member_id  => 'moge',
        message_id => 'チェックリストを削除しました。: [ComicMarket999] circle 3 / author 3 (member_id=moge, count=1)',
        parameters => qq!["チェックリストを削除しました。","circle_id","$ID[2]","member_id","moge","count","1"]!,
    };
}
