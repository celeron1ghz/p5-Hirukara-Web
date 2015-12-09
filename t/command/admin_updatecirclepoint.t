use utf8;
use strict;
use t::Util;
use Test::More tests => 3;

my $m = create_mock_object;
my @circles = (
    { circle_sym => "Ａ" },
    { circle_sym => "Ｂ" },
    { circle_sym => "Ｃ" },
);

{
    for my $c (@circles)    {
        create_mock_circle($m, %$c);
    }

    delete_cached_log $m;
}

subtest "all updated" => sub {
    plan tests => 6;
    ## clearing default point first
    $m->db->update(circle => { circle_point => 0, area => "" });
    my @before = $m->db->search('circle')->all;
    is_deeply [ map { $_->circle_point } @before ], [0,0,0];
    is_deeply [ map { $_->area } @before ], ["", "", ""];

    ## running update
    $m->run_command('admin.update_circle_point' => { exhibition => 'ComicMarket999' });
    my @after = $m->db->search('circle')->all;
    is_deeply [ map { $_->circle_point } @after ], [10,2,2];
    is_deeply [ map { $_->area } @after ], ["東123壁", "東1", "東1"];

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => 'サークルポイントを更新しました。 (all=3, changed=3, not_change=)',
        parameters => '["サークルポイントを更新しました。","all","3","changed","3","not_change",null]',
    };
};

subtest "nothing updated" => sub {
    plan tests => 3;
    ## running update
    $m->run_command('admin.update_circle_point' => { exhibition => 'ComicMarket999' });
    is_deeply [ map { $_->circle_point } $m->db->search('circle')->all ], [10,2,2];

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => 'サークルポイントを更新しました。 (all=3, changed=, not_change=3)',
        parameters => '["サークルポイントを更新しました。","all","3","changed",null,"not_change","3"]',
    };
};

subtest "partly updated" => sub {
    plan tests => 4;
    ## clearing default point first
    my $c = $m->db->single("circle");
    $m->db->update($c, { circle_point => 0 });
    is_deeply [ map { $_->circle_point } $m->db->search('circle')->all ], [0,2,2];

    ## running update
    $m->run_command('admin.update_circle_point' => { exhibition => 'ComicMarket999' });
    is_deeply [ map { $_->circle_point } $m->db->search('circle')->all ], [10,2,2];

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => 'サークルポイントを更新しました。 (all=3, changed=1, not_change=2)',
        parameters => '["サークルポイントを更新しました。","all","3","changed","1","not_change","2"]',
    };
};
