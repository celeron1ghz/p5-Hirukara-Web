use utf8;
use strict;
use t::Util;
use Test::More tests => 3;

my $m = create_mock_object;

subtest "data create ok" => sub {
    plan tests => 2;
    supress_log {
        my @ids = map { $m->run_command('circle.create' => {
            comiket_no    => $_,
            day           => "bb",
            circle_sym    => "cc",
            circle_num    => "dd",
            circle_flag   => "ee",
            circle_name   => "ff",
            circle_author => "author",
            area          => "area",
            circlems      => "circlems",
            url           => "url",
        })->id } 1 .. 10;

        $m->run_command('checklist.create' => { member_id => "moge", circle_id => $_ }) for @ids[0 .. 4];
        $m->run_command('checklist.create' => { member_id => "fuga", circle_id => $_ }) for @ids[5 .. 8];
    };

    my $ret = $m->run_command('checklist.joined' => {  where => {} });
    is @$ret, 9, "ret count ok";
    delete_actionlog_ok $m, 9;
};

subtest "not deleted on condition not match" => sub {
    plan tests => 4;
    output_ok {
        my $ret = $m->run_command('checklist.deleteall' => {  member_id => 'aaaaaa', exhibition => 'moge' });
        is $ret, "0E0", "ret count ok";
    } qr/\[INFO\] チェックリストを全削除しました。 \(member_id=aaaaaa, exhibition=moge, count=0E0\)/;

    actionlog_ok $m, { message_id => 'チェックリストを全削除しました。', circle_id => undef };
    delete_actionlog_ok $m, 1;
};

subtest "deleted on condition match" => sub {
    plan tests => 5;
    output_ok {
        my $ret = $m->run_command('checklist.deleteall' => {  member_id => 'moge', exhibition => '1' });
        is $ret, 1, "ret count ok";
    } qr/\[INFO\] チェックリストを全削除しました。 \(member_id=moge, exhibition=1, count=1\)/;

    my $ret = $m->run_command('checklist.joined' => {  where => {} });
    is @$ret, 8, "ret count ok";

    actionlog_ok $m, { message_id => 'チェックリストを全削除しました。', circle_id => undef };
    delete_actionlog_ok $m, 1;
};
