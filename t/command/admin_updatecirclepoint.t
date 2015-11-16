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
        $m->run_command('circle.create' => {
            comiket_no    => "aa",
            day           => "bb",
            circle_sym    => "cc",
            circle_num    => "10",
            circle_flag   => "a",
            circle_name   => "ff",
            circle_author => "author",
            area          => "area",
            circlems      => "circlems",
            url           => "url",
            circle_type   => 0,
            %$c,
        });
    }

    delete_cached_log $m;
}

subtest "all updated" => sub {
    plan tests => 4;
    ## clearing default point first
    $m->db->update(circle => { circle_point => 0 });
    is_deeply [ map { $_->circle_point } $m->db->search('circle')->all ], [0,0,0];

    ## running update
    $m->run_command('admin.update_circle_point' => { exhibition => 'aa' });
    is_deeply [ map { $_->circle_point } $m->db->search('circle')->all ], [10,2,2];

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
    $m->run_command('admin.update_circle_point' => { exhibition => 'aa' });
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
    $c->circle_point(0);
    $c->update;
    is_deeply [ map { $_->circle_point } $m->db->search('circle')->all ], [0,2,2];

    ## running update
    $m->run_command('admin.update_circle_point' => { exhibition => 'aa' });
    is_deeply [ map { $_->circle_point } $m->db->search('circle')->all ], [10,2,2];

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        message_id => 'サークルポイントを更新しました。 (all=3, changed=1, not_change=2)',
        parameters => '["サークルポイントを更新しました。","all","3","changed","1","not_change","2"]',
    };
};
