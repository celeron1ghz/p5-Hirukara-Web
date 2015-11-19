use utf8;
use strict;
use t::Util;
use Test::More tests => 5;

my $m = create_mock_object;

sub create_checklist    {
    my %args = @_;
    my $dbargs = { %args };
    $m->run_command('checklist.create' => $dbargs);
}

{
    my $c1 = create_mock_circle($m, comiket_no => "moge1", day => "1");
    my $c2 = create_mock_circle($m, comiket_no => "moge1", day => "1", circle_name => "name2");
    my $c3 = create_mock_circle($m, comiket_no => "moge1", day => "2", circle_name => "name3");
    my $c4 = create_mock_circle($m, comiket_no => "moge1", day => "2", circle_name => "name4");
    my $c5 = create_mock_circle($m, comiket_no => "moge1", day => "2", circle_name => "name5");
    my $c6 = create_mock_circle($m, comiket_no => "moge1", day => "3", circle_name => "name6");
    my $c7 = create_mock_circle($m, comiket_no => "moge1", day => "3", circle_name => "name7");
    my $c8 = create_mock_circle($m, comiket_no => "moge1", day => "3", circle_name => "name8");
    my $c9 = create_mock_circle($m, comiket_no => "moge1", day => "3", circle_name => "name9");

    create_checklist(member_id => $_, circle_id => $c1->id) for qw/moge fuga/;
    create_checklist(member_id => $_, circle_id => $c2->id) for qw/moge fuga foo/;
    create_checklist(member_id => $_, circle_id => $c3->id) for qw/moge fuga      piyo/;
    create_checklist(member_id => $_, circle_id => $c4->id) for qw/moge fuga foo/;
    create_checklist(member_id => $_, circle_id => $c5->id) for qw/moge      foo/;
    create_checklist(member_id => $_, circle_id => $c6->id) for qw/moge           piyo/;
    create_checklist(member_id => $_, circle_id => $c7->id) for qw/moge/;
    create_checklist(member_id => $_, circle_id => $c8->id) for qw/moge/;
    create_checklist(member_id => $_, circle_id => $c9->id) for qw/moge           piyo/;

    ## circle comment
    $m->run_command('circle.update' => { circle_id => $c1->id, member_id => 'moge', comment => "" }); ## empty string
    $m->run_command('circle.update' => { circle_id => $c3->id, member_id => 'moge', comment => "mogemoge" });
    $m->run_command('circle.update' => { circle_id => $c6->id, member_id => 'moge', comment => "fugafuga" });
    $m->run_command('circle.update' => { circle_id => $c9->id, member_id => 'moge', comment => "fugafuga" });

    ## checklist comment
    $m->run_command('checklist.update' => { circle_id => $c2->id, member_id => 'moge', comment => "fugafuga" });
    $m->run_command('checklist.update' => { circle_id => $c4->id, member_id => 'moge', comment => "fugafuga" });
    $m->run_command('checklist.update' => { circle_id => $c8->id, member_id => 'moge', comment => "" }); ## empty string
    $m->run_command('checklist.update' => { circle_id => $c3->id, member_id => 'piyo', comment => "mogemoge" });
    $m->run_command('checklist.update' => { circle_id => $c6->id, member_id => 'piyo', comment => "mogemoge" });
    $m->run_command('checklist.update' => { circle_id => $c9->id, member_id => 'piyo', comment => "mogemoge" });
    $m->run_command('checklist.update' => { circle_id => $c2->id, member_id => 'foo', comment => "mogemoge" });
    $m->run_command('checklist.update' => { circle_id => $c4->id, member_id => 'foo', comment => "mogemoge" });
    $m->run_command('checklist.update' => { circle_id => $c5->id, member_id => 'foo', comment => "" });
};

subtest "member 'moge' statistic select ok" => sub {
    plan tests => 1;

    ## normal select
    my $ret = $m->run_command('statistic.single' => {
        member_id => 'moge',
        exhibition => 'moge1',
    });

    is_deeply $ret->get_columns, {
        day1_count => 2,
        day2_count => 3,
        day3_count => 4,
        all_count  => 9,
        circle_commented_count => 3, 
        circle_commented_percentage => 33, 
        circle_no_comment_count => 6, 

        checklist_commented_count => 2, 
        checklist_commented_percentage => 22, 
        checklist_no_comment_count => 7, 
    }, "return value ok";
};

subtest "member 'fuga' statistic select ok" => sub {
    plan tests => 1;

    ## checklist is zero percent
    my $ret = $m->run_command('statistic.single' => {
        member_id => 'fuga',
        exhibition => 'moge1',
    });

    is_deeply $ret->get_columns, {
        day1_count => 2,
        day2_count => 2,
        day3_count => 0,
        all_count  => 4,
        circle_commented_count => 1, 
        circle_commented_percentage => 25, 
        circle_no_comment_count => 3, 

        checklist_commented_count => 0, 
        checklist_commented_percentage => 0, 
        checklist_no_comment_count => 4, 
    }, "return value ok";
};

subtest "member 'foo' statistic select ok" => sub {
    plan tests => 1;

    ## circle is zero percent
    my $ret = $m->run_command('statistic.single' => {
        member_id => 'foo',
        exhibition => 'moge1',
    });

    is_deeply $ret->get_columns, {
        day1_count => 1,
        day2_count => 2,
        day3_count => 0,
        all_count  => 3,
        circle_commented_count => 0, 
        circle_commented_percentage => 0, 
        circle_no_comment_count => 3, 

        checklist_commented_count => 2, 
        checklist_commented_percentage => 66, 
        checklist_no_comment_count => 1, 
    }, "return value ok";
};

subtest "member 'piyo' statistic select ok" => sub {
    plan tests => 1;

    ## all 100 percent
    my $ret = $m->run_command('statistic.single' => {
        member_id => 'piyo',
        exhibition => 'moge1',
    });

    is_deeply $ret->get_columns, {
        day1_count => 0,
        day2_count => 1,
        day3_count => 2,
        all_count  => 3,
        circle_commented_count => 3, 
        circle_commented_percentage => 100, 
        circle_no_comment_count => 0, 

        checklist_commented_count => 3, 
        checklist_commented_percentage => 100, 
        checklist_no_comment_count => 0, 
    }, "return value ok";
};

subtest "member 'mogefuga' statistic select ok" => sub {
    plan tests => 1;

    ## not exist user
    my $ret = $m->run_command('statistic.single' => {
        member_id => 'mogefuga',
        exhibition => 'moge1',
    });

    is_deeply $ret->get_columns, {
        day1_count => 0,
        day2_count => 0,
        day3_count => 0,
        all_count  => 0,
        circle_commented_count => 0, 
        circle_commented_percentage => undef, 
        circle_no_comment_count => 0, 

        checklist_commented_count => 0, 
        checklist_commented_percentage => undef,
        checklist_no_comment_count => 0, 
    }, "return value ok";
};
