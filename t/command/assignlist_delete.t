use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use Encode;

my $m = create_mock_object;
$m->run_command('assign_list.create' => { day => 1, run_by => '' });
$m->run_command('assign_list.create' => { day => 1, run_by => '' });
$m->run_command('assign_list.create' => { day => 1, run_by => '' });
$m->run_command('assign.create' => { circle_ids => [123], assign_list_id => 1, run_by => 'moge' });
delete_cached_log $m;

subtest "assign list delete fail on assign exists" => sub {
    plan tests => 2;
    exception_ok { $m->run_command('assign_list.delete' => { list_id => 1, run_by => 'moge' }) }
        "Hirukara::DB::AssignStillExistsException"
        , qr/割り当てリスト '新規割当リスト' はまだ割り当てが存在します。割り当ての削除を行う際は全ての割り当てを削除してから行ってください。\(aid=1\)/
        , "exception thrown on assign exist yet";
};

subtest "assign list delete ok on empty list" => sub {
    plan tests => 2;
    $m->run_command('assign_list.delete' => { list_id => 2, run_by => 'moge' });
 
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => undef,
        message_id => '割り当てリストを削除しました。 (list_id=2, name=新規割当リスト, run_by=moge)',
        parameters => '["割り当てリストを削除しました。","list_id","2","name","新規割当リスト","run_by","moge"]',
    };
};

subtest "error om not exist assign list delete" => sub {
    plan tests => 2;
    exception_ok { $m->run_command('assign_list.delete' => { list_id => 2, run_by => 'moge' }) }
        'Hirukara::DB::NoSuchRecordException'
        , qr/^データが存在しません。\(table=assign_list, id=2, mid=moge\)/
};

subtest "assign list delete ok on being empty list" => sub {
    plan tests => 2;
    $m->run_command('assign.delete' => { id => 1, run_by => 'moge' });
    $m->run_command('assign_list.delete' => { list_id => 1, run_by => 'moge' });
 
    test_actionlog_ok $m
        , {
            id         => 1,
            circle_id  => undef,
            member_id  => undef,
            message_id => '割り当てを削除しました。 (id=1, circle_id=123, run_by=moge)',
            parameters => '["割り当てを削除しました。","id","1","circle_id","123","run_by","moge"]',
        }, {
            id         => 2,
            circle_id  => undef,
            member_id  => undef,
            message_id => '割り当てリストを削除しました。 (list_id=1, name=新規割当リスト, run_by=moge)',
            parameters => '["割り当てリストを削除しました。","list_id","1","name","新規割当リスト","run_by","moge"]',
        };
};
