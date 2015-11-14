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
        my $ret = $m->run_command('circle.create' => {
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
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=, delete_count=)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count",0,"delete_count",0]',
    };
};

subtest "die on specify not exist circle in create" => sub {
    plan tests => 3;
    throws_ok {
        $m->run_command('checklist.bulk_operation' => {
            member_id => 'moge',
            create_chk_ids => ['aaa'],
            delete_chk_ids => [],
        });
    } qr/no such circle id=aaa/, "die on not exist circle";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=1, delete_count=)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count","1","delete_count",0]',
    };
};

subtest "die on specify not exist circle in delete" => sub {
    plan tests => 3;
    throws_ok {
        $m->run_command('checklist.bulk_operation' => {
            member_id => 'moge',
            create_chk_ids => [],
            delete_chk_ids => ['bbb'],
        });
    } qr/no such circle id=bbb/, "die on not exist circle";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
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
        circle_id => undef,
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=5, delete_count=)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count","5","delete_count",0]',
    }, {
        id => 2,
        circle_id => $ID[0],
        message_id => 'チェックリストを作成しました。 (サークル名=circle 1 (author), メンバー名=moge)',
        parameters => '["チェックリストを作成しました。","circle_id","50ef491d06540e7d8b0a4f2161101298","member_id","moge"]',
    }, {
        id => 3,
        circle_id => $ID[1],
        message_id => 'チェックリストを作成しました。 (サークル名=circle 2 (author), メンバー名=moge)',
        parameters => '["チェックリストを作成しました。","circle_id","222fd52fe28550797ee67b2cb5d3dac4","member_id","moge"]',
    }, {
        id => 4,
        circle_id  => $ID[2],
        message_id => 'チェックリストを作成しました。 (サークル名=circle 3 (author), メンバー名=moge)',
        parameters => '["チェックリストを作成しました。","circle_id","cee5735b5beb1d90f3d4363aea645a05","member_id","moge"]',
    }, {
        id => 5,
        circle_id => $ID[3],
        message_id => 'チェックリストを作成しました。 (サークル名=circle 4 (author), メンバー名=moge)',
        parameters => '["チェックリストを作成しました。","circle_id","45a4a52d74c6788c0a06ed2778bb10ee","member_id","moge"]',
    }, {
        id => 6,
        circle_id  => $ID[4],
        message_id => 'チェックリストを作成しました。 (サークル名=circle 5 (author), メンバー名=moge)',
        parameters => '["チェックリストを作成しました。","circle_id","98a249384e5fbbcd1a2788c4fa461f87","member_id","moge"]',
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
        circle_id => undef,
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=, delete_count=2)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count",0,"delete_count","2"]',
    }, {
        id => 2,
        circle_id => $ID[3],
        message_id => 'チェックリストを削除しました。 (サークル名=circle 4 (author), メンバー名=moge, count=1)',
        parameters => '["チェックリストを削除しました。","circle_id","45a4a52d74c6788c0a06ed2778bb10ee","member_id","moge","count",1]',
    }, {
        id => 3,
        circle_id => $ID[4],
        message_id => 'チェックリストを削除しました。 (サークル名=circle 5 (author), メンバー名=moge, count=1)',
        parameters => '["チェックリストを削除しました。","circle_id","98a249384e5fbbcd1a2788c4fa461f87","member_id","moge","count",1]',
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
        message_id => 'サークルの一括追加・一括削除を行います。 (member_id=moge, create_count=2, delete_count=3)',
        parameters => '["サークルの一括追加・一括削除を行います。","member_id","moge","create_count","2","delete_count","3"]',
    }, {
        id => 2,
        circle_id  => $ID[3],
        message_id => 'チェックリストを作成しました。 (サークル名=circle 4 (author), メンバー名=moge)',
        parameters => '["チェックリストを作成しました。","circle_id","45a4a52d74c6788c0a06ed2778bb10ee","member_id","moge"]',
    }, {
        id => 3,
        circle_id  => $ID[4],
        message_id => 'チェックリストを作成しました。 (サークル名=circle 5 (author), メンバー名=moge)',
        parameters => '["チェックリストを作成しました。","circle_id","98a249384e5fbbcd1a2788c4fa461f87","member_id","moge"]',
    }, {
        id => 4,
        circle_id  => $ID[0],
        message_id => 'チェックリストを削除しました。 (サークル名=circle 1 (author), メンバー名=moge, count=1)',
        parameters => '["チェックリストを削除しました。","circle_id","50ef491d06540e7d8b0a4f2161101298","member_id","moge","count",1]',
    }, {
        id => 5,
        circle_id  => $ID[1],
        message_id => 'チェックリストを削除しました。 (サークル名=circle 2 (author), メンバー名=moge, count=1)',
        parameters => '["チェックリストを削除しました。","circle_id","222fd52fe28550797ee67b2cb5d3dac4","member_id","moge","count",1]',
    }, {
        id => 6,
        circle_id  => $ID[2],
        message_id => 'チェックリストを削除しました。 (サークル名=circle 3 (author), メンバー名=moge, count=1)',
        parameters => '["チェックリストを削除しました。","circle_id","cee5735b5beb1d90f3d4363aea645a05","member_id","moge","count",1]',
    };
}
