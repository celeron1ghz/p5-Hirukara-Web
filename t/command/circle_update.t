use utf8;
use strict;
use t::Util;
use Test::More tests => 6;
use Test::Exception;

my $m = create_mock_object;
my $ID;

$m->run_command('circle_type.create' => { type_name => '身内', scheme => 'info' });
$m->run_command('circle_type.create' => { type_name => '身内2', scheme => 'info' });
$m->run_command('circle_type.create' => { type_name => '身内3', scheme => 'info' });
$m->run_command('circle_type.create' => { type_name => 'エラーデータ', scheme => 'info' });
delete_cached_log $m;

subtest "creating circle first" => sub {
    plan tests => 3;
    my $c = create_mock_circle $m;
    ok $c, "circle create ok";
    $ID = $c->id;

    my $c2 = $m->run_command('circle.single' => { circle_id => $ID });
    is $c2->circle_type, 0,     "circle_type ok";
    is $c2->comment,     undef, "comment ok";
    delete_cached_log $m;
};

subtest "not updating" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => {
        member_id => "moge",
        circle_id => $ID,
    });

    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, 0,     "circle_type ok";
    is $c->comment,     undef, "comment ok";
    test_actionlog_ok $m;
};

subtest "unknown circle_type" => sub {
    plan tests => 3;
    throws_ok {
        my $ret = $m->run_command('circle.update' => {
            member_id => "moge",
            circle_id => $ID,
            circle_type => 1234,
            comment => "mogemogefugafuga"
        });
    } qr/no such circle type '1234'/, 'error on unknown circle_type';
    test_actionlog_ok $m; 
};

subtest "updating both" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => {
        member_id => "moge",
        circle_id => $ID,
        circle_type => 1,
        comment => "mogemogefugafuga"
    });

    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, "1", "circle_type ok";
    is $c->comment,     "mogemogefugafuga", "comment ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        message_id => 'サークルの属性を更新しました。: [ComicMarket999] circle / author (member_id=moge, before_type=, after_type=身内)',
        parameters => qq!["サークルの属性を更新しました。","circle_id","$ID","member_id","moge","before_type","","after_type","身内"]!,
    }, {
        id         => 2,
        circle_id  => $ID,
        message_id => 'サークルのコメントを更新しました。: [ComicMarket999] circle / author (member_id=moge)',
        parameters => qq!["サークルのコメントを更新しました。","circle_id","$ID","member_id","moge"]!,
    };
};

subtest "updating circle_type" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => {
        member_id => "moge",
        circle_id => $ID,
        circle_type => 4,
    });

    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, "4", "circle_type ok";
    is $c->comment,     "",   "comment ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        message_id => 'サークルの属性を更新しました。: [ComicMarket999] circle / author (member_id=moge, before_type=身内, after_type=エラーデータ)',
        parameters => qq!["サークルの属性を更新しました。","circle_id","$ID","member_id","moge","before_type","身内","after_type","エラーデータ"]!,
    }, {
        id         => 2,
        circle_id  => $ID,
        message_id => 'サークルのコメントを更新しました。: [ComicMarket999] circle / author (member_id=moge)',
        parameters => qq!["サークルのコメントを更新しました。","circle_id","$ID","member_id","moge"]!,
    };
};

subtest "updating comment" => sub {
    plan tests => 4;
    my $ret = $m->run_command('circle.update' => {
        member_id => "moge",
        circle_id => $ID,
        comment   => "piyopiyo",
    });

    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, "",         "circle_type ok";
    is $c->comment,     "piyopiyo", "comment ok";
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $ID,
        message_id => 'サークルの属性を更新しました。: [ComicMarket999] circle / author (member_id=moge, before_type=エラーデータ, after_type=)',
        parameters => qq!["サークルの属性を更新しました。","circle_id","$ID","member_id","moge","before_type","エラーデータ","after_type",""]!,
    }, {
        id         => 2,
        circle_id  => $ID,
        message_id => 'サークルのコメントを更新しました。: [ComicMarket999] circle / author (member_id=moge)',
        parameters => qq!["サークルのコメントを更新しました。","circle_id","$ID","member_id","moge"]!,
    };
};
