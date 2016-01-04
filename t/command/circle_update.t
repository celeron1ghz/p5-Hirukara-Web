use utf8;
use strict;
use t::Util;
use Test::More tests => 6;
use Test::Exception;

my $m = create_mock_object;
my $ID;

$m->run_command('circle_type.create' => { type_name => '身内', scheme => 'info', run_by => 'moge' });
$m->run_command('circle_type.create' => { type_name => '身内2', scheme => 'info', run_by => 'moge' });
$m->run_command('circle_type.create' => { type_name => '身内3', scheme => 'info', run_by => 'moge' });
$m->run_command('circle_type.create' => { type_name => 'エラーデータ', scheme => 'info', run_by => 'moge' });
delete_cached_log $m;

subtest "creating circle first" => sub {
    plan tests => 3;
    my $c = create_mock_circle $m;
    ok $c, "circle create ok";
    $ID = $c->id;

    my $c2 = $m->db->single_by_id(circle => $ID);
    is $c2->circle_type, 0,     "circle_type ok";
    is $c2->comment,     undef, "comment ok";
    delete_cached_log $m;
};

subtest "not updating" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => { run_by => "moge", circle_id => $ID });

    my $c = $m->db->single_by_id(circle => $ID);
    is $c->circle_type, 0,     "circle_type ok";
    is $c->comment,     undef, "comment ok";
    test_actionlog_ok $m;
};

subtest "unknown circle_type" => sub {
    plan tests => 3;
    throws_ok {
        my $ret = $m->run_command('circle.update' => {
            circle_id => $ID,
            circle_type => 1234,
            comment => "mogemogefugafuga",
            run_by => "moge",
        });
    } qr/no such circle type '1234'/, 'error on unknown circle_type';
    test_actionlog_ok $m; 
};

subtest "updating both" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => {
        circle_id => $ID,
        circle_type => 1,
        comment => "mogemogefugafuga",
        run_by => "moge",
    });

    my $c = $m->db->single_by_id(circle => $ID);
    is $c->circle_type, "1", "circle_type ok";
    is $c->comment,     "mogemogefugafuga", "comment ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => undef,
        message_id => 'サークルの属性を更新しました。: [ComicMarket999] circle / author (before_type=, after_type=身内, run_by=moge)',
        parameters => qq!["サークルの属性を更新しました。","circle_id","$ID","before_type","","after_type","身内","run_by","moge"]!,
    }, {
        id         => 2,
        circle_id  => $ID,
        member_id  => undef,
        message_id => 'サークルのコメントを更新しました。: [ComicMarket999] circle / author (run_by=moge)',
        parameters => qq!["サークルのコメントを更新しました。","circle_id","$ID","run_by","moge"]!,
    };
};

subtest "updating circle_type" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => {
        circle_id => $ID,
        circle_type => 4,
        run_by => "moge",
    });

    my $c = $m->db->single_by_id(circle => $ID);
    is $c->circle_type, "4", "circle_type ok";
    is $c->comment,     "",   "comment ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => undef,
        message_id => 'サークルの属性を更新しました。: [ComicMarket999] circle / author (before_type=身内, after_type=エラーデータ, run_by=moge)',
        parameters => qq!["サークルの属性を更新しました。","circle_id","$ID","before_type","身内","after_type","エラーデータ","run_by","moge"]!,
    }, {
        id         => 2,
        circle_id  => $ID,
        member_id  => undef,
        message_id => 'サークルのコメントを更新しました。: [ComicMarket999] circle / author (run_by=moge)',
        parameters => qq!["サークルのコメントを更新しました。","circle_id","$ID","run_by","moge"]!,
    };
};

subtest "updating comment" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => {
        circle_id => $ID,
        comment   => "piyopiyo",
        run_by    => "moge",
    });

    my $c = $m->db->single_by_id(circle => $ID);
    is $c->circle_type, "",         "circle_type ok";
    is $c->comment,     "piyopiyo", "comment ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        member_id  => undef,
        message_id => 'サークルの属性を更新しました。: [ComicMarket999] circle / author (before_type=エラーデータ, after_type=, run_by=moge)',
        parameters => qq!["サークルの属性を更新しました。","circle_id","$ID","before_type","エラーデータ","after_type","","run_by","moge"]!,
    }, {
        id         => 2,
        circle_id  => $ID,
        member_id  => undef,
        message_id => 'サークルのコメントを更新しました。: [ComicMarket999] circle / author (run_by=moge)',
        parameters => qq!["サークルのコメントを更新しました。","circle_id","$ID","run_by","moge"]!,
    };
};
