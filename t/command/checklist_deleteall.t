use utf8;
use strict;
use t::Util;
use Test::More tests => 3;

my $m = create_mock_object;

subtest "data create ok" => sub {
    plan tests => 1;
    my @ids = map { create_mock_circle($m, comiket_no  => $_)->id } 1 .. 10;

    $m->run_command('checklist.create' => { member_id => "moge", circle_id => $_ }) for @ids[0 .. 4];
    $m->run_command('checklist.create' => { member_id => "fuga", circle_id => $_ }) for @ids[5 .. 8];

    my $ret = $m->db->search_all_joined({});
    is @$ret, 10, "ret count ok";
    delete_cached_log $m;
};

subtest "not deleted on condition not match" => sub {
    plan tests => 3;
    my $ret = $m->run_command('checklist.delete_all' => { member_id => 'aaaaaa', exhibition => 'moge' });
    is $ret, "0", "ret count ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => 'チェックリストを全削除しました。 (member_id=aaaaaa, exhibition=moge, count=)',
        parameters => '["チェックリストを全削除しました。","member_id","aaaaaa","exhibition","moge","count",0]',
    };
};

subtest "deleted on condition match" => sub {
    plan tests => 4;
    my $ret = $m->run_command('checklist.delete_all' => { member_id => 'moge', exhibition => '1' });
    is $ret, 1, "ret count ok";

    my $ret = $m->db->search_all_joined({});
    is @$ret, 10, "ret count ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => 'チェックリストを全削除しました。 (member_id=moge, exhibition=1, count=1)',
        parameters => '["チェックリストを全削除しました。","member_id","moge","exhibition","1","count","1"]',
    };
};
