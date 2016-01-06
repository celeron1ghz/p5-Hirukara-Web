use utf8;
use strict;
use t::Util;
use Test::More tests => 3;

my $m    = create_mock_object;
my $list = $m->run_command('assign_list.create' => { day => 1, run_by => 'mogemoge' });
my $mem  = $m->run_command('member.create' => { id => '123', member_id => 'mogemoge', member_name => 'もげもげ', image_url => '', run_by => 'mogemoge' });

subtest "not assigned ok" => sub {
    plan tests => 1;
    is $m->db->single_by_id(assign_list => $list->id)->assign_list_label, '[ID:1 ComicMarket999 1日目] 新規割当リスト (未割当)';
};

subtest "not exist member ok" => sub {
    plan tests => 1;
    $m->run_command('assign_list.update' => {
        assign_id => $list->id,
        assign_member_id => 'fugafuga',
        assign_name => 'list name',
        run_by => 'piyopiyo',
    });

    ## XXX: member not exist in database is treat as 'not assigned';
    is $m->db->single_by_id(assign_list => $list->id)->assign_list_label, '[ID:1 ComicMarket999 1日目] list name (未割当)';
};

subtest "exist member ok" => sub {
    plan tests => 1;
    $m->run_command('assign_list.update' => {
        assign_id => $list->id,
        assign_member_id => 'mogemoge',
        assign_name => 'list name',
        run_by => 'piyopiyo',
    });

    is $m->db->single_by_id(assign_list => $list->id)->assign_list_label, '[ID:1 ComicMarket999 1日目] list name (もげもげ)';
};
