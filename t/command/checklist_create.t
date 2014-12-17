use utf8;
use strict;
use t::Util;
use Test::More tests => 16;
use Hirukara::Command::Circle::Create;
use_ok "Hirukara::Command::Checklist::Single";
use_ok "Hirukara::Command::Checklist::Create";
use_ok "Hirukara::Command::Checklist::Delete";
use_ok "Hirukara::Command::Checklist::Update";

my $m = create_mock_object;
my $ID;

subtest "creating circle" => sub {
    my $c = Hirukara::Command::Circle::Create->new(
        database      => $m->database,
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
    )->run;

    ok $c, "circle create ok";
    $ID = $c->id;
};

subtest "create checklist" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Create->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
        )->run;

        isa_ok $ret, "Hirukara::Database::Row::Checklist";
        is $ret->member_id, "moge", "member_id ok";
        is $ret->circle_id, $ID,    "circle_id ok";
    } qr/\[INFO\] CHECKLIST_CREATE: member_id=moge, circle_id=$ID/;

    actionlog_ok $m, { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};

subtest "duplicate create checklist fail" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Create->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
        )->run;

        ok !$ret, "not created";
    } qr/^$/;

    actionlog_ok $m, { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};


subtest "not exist checklist get fail" => sub {
    ok !Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "9999",
        circle_id => "9090",
    )->run, "check list not return";
};

subtest "exist checklist returned" => sub {
    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => $ID,
    )->run;

    isa_ok $ret, "Hirukara::Database::Row::Checklist";
    is $ret->member_id, "moge", "member_id ok";
    is $ret->circle_id, $ID,    "circle_id ok";
};


subtest "checklist no update on not specify" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => "1122",
        );
    } qr/^$/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => $ID,
    )->run;

    is $ret->count,   1, "count ok";
    is $ret->comment, undef, "comment ok";

    actionlog_ok $m, { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};

subtest "updating checklist count" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
            count     => 12,
        )->run;
    } qr/\[INFO\] CHECKLIST_COUNT_UPDATE: circle_id=$ID, circle_name=ff, member_id=moge, before_cnt=1, after_cnt=12/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => $ID,
    )->run;

    is $ret->count,   12, "count ok";
    is $ret->comment, undef, "comment ok";

    actionlog_ok $m
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=1,変更後=12)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};

subtest "updating checklist comment" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
            comment   => "piyopiyo",
        )->run;
    } qr/\[INFO\] CHECKLIST_COMMENT_UPDATE: circle_id=77ca48c9876d9e6c2abad3798b589664, circle_name=ff, member_id=moge/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => $ID,
    )->run;

    is $ret->count,   12,         "count ok";
    is $ret->comment, "piyopiyo", "comment ok";

    actionlog_ok $m
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=1,変更後=12)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};

subtest "updating empty comment" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
            comment   => "",
        )->run;
    } qr/\[INFO\] CHECKLIST_COMMENT_UPDATE: circle_id=77ca48c9876d9e6c2abad3798b589664, circle_name=ff, member_id=moge/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => $ID,
    )->run;

    is $ret->count,   12, "count ok";
    is $ret->comment, "", "comment ok";

    actionlog_ok $m
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=1,変更後=12)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};

subtest "updating both checklist count and comment" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
            count     => "99",
            comment   => "mogefuga",
        )->run;
    } qr/\[INFO\] CHECKLIST_COUNT_UPDATE: circle_id=$ID, circle_name=ff, member_id=moge, before_cnt=12, after_cnt=99/,
      qr/\[INFO\] CHECKLIST_COMMENT_UPDATE: circle_id=$ID, circle_name=ff, member_id=moge/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => $ID,
    )->run;

    is $ret->count,   99,         "count ok";
    is $ret->comment, "mogefuga", "comment ok";

    actionlog_ok $m
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=12,変更後=99)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=1,変更後=12)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};


subtest "not exist checklist deleting" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Delete->new(
            database  => $m->database,
            member_id => "6666",
            circle_id => $ID,
        )->run;

        ok !$ret, "no return on not exist checklist";
    } qr/\[INFO\] CHECKLIST_DELETE: circle_id=$ID, circle_name=ff, member_id=6666, count=0/;

    actionlog_ok $m,
        , { message => q/6666 さんが 'ff' を削除しました/, type => 'チェックの削除' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=12,変更後=99)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=1,変更後=12)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};

subtest "exist checklist deleting" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Delete->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
        )->run;

        is $ret, 1, "deleted count ok";
    } qr/\[INFO\] CHECKLIST_DELETE: circle_id=$ID, circle_name=ff, member_id=moge, count=1/;

    actionlog_ok $m,
        , { message => q/moge さんが 'ff' を削除しました/, type => 'チェックの削除' },
        , { message => q/6666 さんが 'ff' を削除しました/, type => 'チェックの削除' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=12,変更後=99)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストのコメントを変更しました。/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' のチェックリストの情報を変更しました。(変更前=1,変更後=12)/, type => 'チェックリスト情報の更新' },
        , { message => q/moge さんが 'ff' を追加しました/, type => 'チェックの追加' };
};
