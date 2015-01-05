use utf8;
use strict;
use t::Util;
use Time::Piece;
use Test::More tests => 9;
use_ok 'Hirukara::Command::Notice::Update';
use_ok 'Hirukara::Command::Notice::Select';
use_ok 'Hirukara::Command::Notice::Single';

my $m = create_mock_object;
my $now = time;
my $dt1;
my $dt2;
my $dt3;
my $dt4;

subtest "create notice without id ok" => sub {
    my $ret;

    output_ok {
        $ret = Hirukara::Command::Notice::Update->new(database => $m->database, member_id => 'mogemoge', title => "title 1", text => 'fugafuga')->run;
    } qr/\[INFO\] NOTICE_CREATE: id=1, key=$now, member_id=mogemoge, title=title 1, text_length=8/;

    is_deeply $ret->get_columns, {
        id         => 1,
        key        => $now,
        member_id  => "mogemoge",
        title      => "title 1",
        text       => "fugafuga",
        created_at => ($dt1 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
    }, "data structure ok";

    actionlog_ok $m
        ,{ type => "告知の作成", message => "mogemoge さんが告知を作成しました。(タイトル=title 1)" };
};

subtest "create notice with id ok" => sub {
    my $ret;

    output_ok {
        sleep 1;
        $ret = Hirukara::Command::Notice::Update->new(database => $m->database, key => "9999999999", member_id => 'moge', title => "title 2", text => 'fuga')->run;
    } qr/\[INFO\] NOTICE_UPDATE: id=2, key=9999999999, member_id=moge, title=title 2, text_length=4/;

    is_deeply $ret->get_columns, {
        id         => 2,
        key        => "9999999999",
        member_id  => "moge",
        title      => "title 2",
        text       => "fuga",
        created_at => ($dt2 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
    }, "data structure ok";

    actionlog_ok $m
        ,{ type => "告知の変更", message => "moge さんが告知の内容を変更しました。(タイトル=title 2)" }
        ,{ type => "告知の作成", message => "mogemoge さんが告知を作成しました。(タイトル=title 1)" };
};

subtest "notice select ok" => sub {
    my $ret = Hirukara::Command::Notice::Select->new(database => $m->database)->run;

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "2",
            key        => "9999999999",
            title      => "title 2",
            text       => "fuga",
            member_id  => "moge",
            created_at => $dt2,
        },{
            id         => "1",
            key        => $now,
            title      => "title 1",
            text       => "fugafuga",
            member_id  => "mogemoge",
            created_at => $dt1,
        }
    ], "data structure is ok";

    actionlog_ok $m
        ,{ type => "告知の変更", message => "moge さんが告知の内容を変更しました。(タイトル=title 2)" }
        ,{ type => "告知の作成", message => "mogemoge さんが告知を作成しました。(タイトル=title 1)" };
};

subtest "add new notice and that is selected" => sub {
    supress_log {
        sleep 1;
        Hirukara::Command::Notice::Update->new(database => $m->database, key => "9999999999", member_id => 'mogumogu', title => "title 333", text => 'nemui')->run;
    };

    my $ret = Hirukara::Command::Notice::Select->new(database => $m->database)->run;

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "3",
            key        => "9999999999",
            title      => "title 333",
            text       => "nemui",
            member_id  => "mogumogu",
            created_at => ($dt3 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
        },{
            id         => "1",
            key        => $now,
            title      => "title 1",
            text       => "fugafuga",
            member_id  => "mogemoge",
            created_at => $dt1,
        }
    ], "data structure is ok";

    actionlog_ok $m
        ,{ type => "告知の変更", message => "mogumogu さんが告知の内容を変更しました。(タイトル=title 333)" }
        ,{ type => "告知の変更", message => "moge さんが告知の内容を変更しました。(タイトル=title 2)" }
        ,{ type => "告知の作成", message => "mogemoge さんが告知を作成しました。(タイトル=title 1)" };
};

subtest "add new notice and that is selected" => sub {
    supress_log {
        sleep 1;
        Hirukara::Command::Notice::Update->new(database => $m->database, key => "$now", member_id => 'berobero', title => "title 4444", text => 'zuzuzu')->run;
    };

    my $ret = Hirukara::Command::Notice::Select->new(database => $m->database)->run;

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "3",
            key        => "9999999999",
            title      => "title 333",
            text       => "nemui",
            member_id  => "mogumogu",
            created_at => $dt3,
        },{
            id         => "4",
            key        => $now,
            title      => "title 4444",
            text       => "zuzuzu",
            member_id  => "berobero",
            created_at => ($dt4 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
        }
    ], "data structure is ok";

    actionlog_ok $m
        ,{ type => "告知の変更", message => "berobero さんが告知の内容を変更しました。(タイトル=title 4444)" }
        ,{ type => "告知の変更", message => "mogumogu さんが告知の内容を変更しました。(タイトル=title 333)" }
        ,{ type => "告知の変更", message => "moge さんが告知の内容を変更しました。(タイトル=title 2)" }
        ,{ type => "告知の作成", message => "mogemoge さんが告知を作成しました。(タイトル=title 1)" };
};

subtest "notice_single works" => sub {
    my $ret = Hirukara::Command::Notice::Single->new(database => $m->database, key => $now)->run;

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "4",
            key        => $now,
            title      => "title 4444",
            text       => "zuzuzu",
            member_id  => "berobero",
            created_at => $dt4,
        },{
            id         => "1",
            key        => $now,
            title      => "title 1",
            text       => "fugafuga",
            member_id  => "mogemoge",
            created_at => $dt1,
        }
    ], "data structure is ok";
};
