use utf8;
use strict;
use t::Util;
use Test::More tests => 7;
use Test::Exception;

my $m = create_mock_object;
my $ID;

supress_log {
    $m->run_command('circle_type.create' => { type_name => '身内', scheme => 'info' });
    $m->run_command('circle_type.create' => { type_name => '身内2', scheme => 'info' });
    $m->run_command('circle_type.create' => { type_name => '身内3', scheme => 'info' });
    $m->run_command('circle_type.create' => { type_name => 'エラーデータ', scheme => 'info' });
    delete_actionlog_ok $m, 4;
};

subtest "creating circle first" => sub {
    plan tests => 4;
    my $c;

    supress_log {
        $c = $m->run_command('circle.create' => {
            comiket_no    => "aa",
            day           => "bb",
            circle_sym    => "cc",
            circle_num    => "dd",
            circle_flag   => "ee",
            circle_name   => "ff",
            circle_author => "author",
            area          => "area",
            circlems      => "circlems",
            url           => "url",
        })
    };

    ok $c, "circle create ok";
    $ID = $c->id;

    my $c2 = $m->run_command('circle.single' => { circle_id => $ID });
    is $c2->circle_type, undef, "circle_type ok";
    is $c2->comment,     undef, "comment ok";
    delete_actionlog_ok $m, 0;
};

subtest "not updating" => sub {
    plan tests => 4;
    output_ok {
        my $ret = $m->run_command('circle.update' => {
            member_id => "moge",
            circle_id => $ID,
        });
    } qr/^$/;

    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, undef, "circle_type ok";
    is $c->comment,     undef, "comment ok";
    delete_actionlog_ok $m, 0;
};


subtest "unknown circle_type" => sub {
    plan tests => 2;
    throws_ok {
        my $ret = $m->run_command('circle.update' => {
            member_id => "moge",
            circle_id => $ID,
            circle_type => 1234,
            comment => "mogemogefugafuga"
        });
    } qr/no such circle type '1234'/, 'error on unknown circle_type';
    delete_actionlog_ok $m, 0;
};

subtest "updating both" => sub {
    plan tests => 5;
    output_ok {
        my $ret = $m->run_command('circle.update' => {
            member_id => "moge",
            circle_id => $ID,
            circle_type => 1,
            comment => "mogemogefugafuga"
        });
    } qr/\[INFO\] サークルの属性を更新しました。 \(サークル名=ff \(author\), メンバー名=moge, before_type=, after_type=身内\)/,
      qr/\[INFO\] サークルのコメントを更新しました。 \(サークル名=ff \(author\), メンバー名=moge\)/;


    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, "1", "circle_type ok";
    is $c->comment,     "mogemogefugafuga", "comment ok";
    delete_actionlog_ok $m, 2;
};

subtest "updating circle_type" => sub {
    plan tests => 5;
    output_ok {
        my $ret = $m->run_command('circle.update' => {
            member_id => "moge",
            circle_id => $ID,
            circle_type => 4,
        });
    } qr/\[INFO\] サークルの属性を更新しました。 \(サークル名=ff \(author\), メンバー名=moge, before_type=身内, after_type=エラーデータ\)/,
      qr/\[INFO\] サークルのコメントを更新しました。 \(サークル名=ff \(author\), メンバー名=moge\)/;

    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, "4", "circle_type ok";
    is $c->comment,     "",   "comment ok";
    delete_actionlog_ok $m, 2;
};

subtest "updating comment" => sub {
    plan tests => 5;
    output_ok {
        my $ret = $m->run_command('circle.update' => {
            member_id => "moge",
            circle_id => $ID,
            comment   => "piyopiyo",
        });
    } qr/\[INFO\] サークルの属性を更新しました。 \(サークル名=ff \(author\), メンバー名=moge, before_type=エラーデータ, after_type=\)/,
      qr/\[INFO\] サークルのコメントを更新しました。 \(サークル名=ff \(author\), メンバー名=moge\)/;

    my $c = $m->run_command('circle.single' => { circle_id => $ID });
    is $c->circle_type, "",         "circle_type ok";
    is $c->comment,     "piyopiyo", "comment ok";
    delete_actionlog_ok $m, 2;
};
