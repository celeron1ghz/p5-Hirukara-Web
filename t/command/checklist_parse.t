use utf8;
use strict;
use t::Util;
use Test::More tests => 5;
use Test::Exception;

my $m    = create_mock_object;
my $ID   = 'bde6eff32e4a3c9b8251329fbb6aedb9';
my $CHK1 = make_temporary_file(<<EOT);
Header,a,ComicMarket86,utf8,source
Circle,2,3,4,5,金,7,Ａ,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
EOT

my $CHK2 = make_temporary_file(<<EOT);
Header,a,ComicMarket86,utf8,source
EOT

subtest "die on current exhibition is not comiket" => sub {
    plan tests => 4;
    exception_ok {
        $m->run_command('checklist.parse' => {
            exhibition => 'mogemoge',
            member_id => 'moge',
            csv_file  => $CHK1,
        });
    } "Hirukara::CSV::NotAComiketException" ,qr/現在受け付けているのはコミケットではないのでチェックリストをアップロードできません。/;

    test_actionlog_ok $m;
};

subtest "die on comiket_no and exhibition is not match" => sub {
    plan tests => 3;
    throws_ok {
        $m->run_command('checklist.parse' => {
            exhibition => 'ComicMarket99',
            member_id => 'moge',
            csv_file  => $CHK1,
        });
    } "Hirukara::CSV::ExhibitionNotMatchException";

    test_actionlog_ok $m;
};

subtest "new circle created" => sub {
    plan tests => 12;
    is $m->db->count('circle'),    0, "circle count ok";
    is $m->db->count('checklist'), 0, "checklist count ok";

    my $ret = $m->run_command('checklist.parse' => {
        exhibition => 'ComicMarket86',
        member_id => 'moge',
        csv_file  => $CHK1,
    });
 
    my $res = $ret->merge_results;
    is_deeply $res->{delete}, {}, "delete is empty";
    is_deeply $res->{exist},  {}, "exist is empty";
    is_deeply [keys %{$res->{create}}], [$ID], "create is not empty";

    is $m->db->count('circle'),    1, "circle count ok";
    is $m->db->count('checklist'), 0, "checklist count ok";

    ok my $circle = $m->db->single(circle => { id => $ID }), "circle created";
    is $circle->circle_name,   "11", "circle_name ok";
    is $circle->circle_author, "13", "circle_author ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => undef,
        message_id => 'サークルを作成しました。: [ComicMarket86] 11 / 13',
        parameters => '["サークルを作成しました。","circle_id","bde6eff32e4a3c9b8251329fbb6aedb9"]',
    },{
        id         => 2,
        circle_id  => $ID,
        member_id  => 'hirukara',
        message_id => 'サークルに本を追加しました。: [ComicMarket86] 11 / 13 (book_name=新刊セット, comment=, member_id=hirukara)',
        parameters => '["サークルに本を追加しました。","circle_id","bde6eff32e4a3c9b8251329fbb6aedb9","book_name","新刊セット","comment",null,"member_id","hirukara"]',
    },{
        id         => 3,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'チェックリストがアップロードされました。 (member_id=moge, exhibition=ComicMarket86, checklist=1, database=, exist=, create=1, delete=)',
        parameters => '["チェックリストがアップロードされました。","member_id","moge","exhibition","ComicMarket86","checklist","1","database",0,"exist",0,"create","1","delete",0]',
    };
};

$m->run_command('checklist.create' => {
    exhibition => 'ComicMarket86',
    circle_id => $ID,
    member_id => 'moge',
});
delete_cached_log $m;

subtest "return structure check of 'exist'" => sub {
    plan tests => 9;
    is $m->db->count('circle'),    1, "circle count ok";
    is $m->db->count('checklist'), 1, "checklist count ok";

    my $ret = $m->run_command('checklist.parse' => {
        exhibition => 'ComicMarket86',
        member_id => 'moge',
        csv_file  => $CHK1,
    });
 
    my $res = $ret->merge_results;
    is_deeply $res->{create}, {},  "create is empty";
    is_deeply $res->{delete},  {}, "delete is empty";
    is_deeply [keys %{$res->{exist}}], [$ID], "exist is not empty";

    is $m->db->count('circle'),    1, "circle count ok";
    is $m->db->count('checklist'), 1, "checklist count ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'チェックリストがアップロードされました。 (member_id=moge, exhibition=ComicMarket86, checklist=1, database=1, exist=1, create=, delete=)',
        parameters => '["チェックリストがアップロードされました。","member_id","moge","exhibition","ComicMarket86","checklist","1","database","1","exist","1","create",0,"delete",0]',
    };
};

subtest "new circle not created because already exist" => sub {
    plan tests => 9;
    is $m->db->count('circle'),    1, "circle count ok";
    is $m->db->count('checklist'), 1, "checklist count ok";

    my $ret = $m->run_command('checklist.parse' => {
        exhibition => 'ComicMarket86',
        member_id => 'moge',
        csv_file  => $CHK2,
    });
 
    my $res = $ret->merge_results;
    is_deeply $res->{create}, {}, "create is empty";
    is_deeply $res->{exist},  {}, "exist is empty";
    is_deeply [keys %{$res->{delete}}], [$ID], "delete is not empty";

    is $m->db->count('circle'),    1, "circle count ok";
    is $m->db->count('checklist'), 1, "checklist count ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => 'チェックリストがアップロードされました。 (member_id=moge, exhibition=ComicMarket86, checklist=, database=1, exist=, create=, delete=1)',
        parameters => '["チェックリストがアップロードされました。","member_id","moge","exhibition","ComicMarket86","checklist",0,"database","1","exist",0,"create",0,"delete","1"]',
    };
};
