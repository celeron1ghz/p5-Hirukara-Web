use strict;
use t::Util;
use Test::More tests => 14;
use_ok "Hirukara::Command::Checklist::Single";
use_ok "Hirukara::Command::Checklist::Create";
use_ok "Hirukara::Command::Checklist::Delete";
use_ok "Hirukara::Command::Checklist::Update";

my $m = create_mock_object;

subtest "create checklist" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Create->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => "1122",
        )->run;

        isa_ok $ret, "Hirukara::Database::Row::Checklist";
        is $ret->member_id, "moge", "member_id ok";
        is $ret->circle_id, "1122", "circle_id ok";
    } qr/\[INFO\] CHECKLIST_CREATE: member_id=moge, circle_id=1122/;
};

subtest "duplicate create checklist fail" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Create->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => "1122",
        )->run;

        ok !$ret, "not created";
    } qr/^$/;
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
        circle_id => "1122",
    )->run;

    isa_ok $ret, "Hirukara::Database::Row::Checklist";
    is $ret->member_id, "moge", "member_id ok";
    is $ret->circle_id, "1122", "circle_id ok";
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
        circle_id => "1122",
    )->run;

    is $ret->count,   1, "count ok";
    is $ret->comment, undef, "comment ok";
};

subtest "updating checklist count" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => "1122",
            count     => 12,
        )->run;
    } qr/\[INFO\] CHECKLIST_COUNT_UPDATE: circle_id=1122, member_id=moge, before=1, after=12/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => "1122",
    )->run;

    is $ret->count,   12, "count ok";
    is $ret->comment, undef, "comment ok";
};

subtest "updating checklist comment" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => "1122",
            comment   => "piyopiyo",
        )->run;
    } qr/\[INFO\] CHECKLIST_COMMENT_UPDATE: circle_id=1122, member_id=moge/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => "1122",
    )->run;

    is $ret->count,   12,         "count ok";
    is $ret->comment, "piyopiyo", "comment ok";
};

subtest "updating checklist comment" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => "1122",
            count     => "99",
            comment   => "mogefuga",
        )->run;
    } qr/\[INFO\] CHECKLIST_COUNT_UPDATE: circle_id=1122, member_id=moge, before=12, after=99/,
      qr/\[INFO\] CHECKLIST_COMMENT_UPDATE: circle_id=1122, member_id=moge/;

    my $ret = Hirukara::Command::Checklist::Single->new(
        database  => $m->database,
        member_id => "moge",
        circle_id => "1122",
    )->run;

    is $ret->count,   99,         "count ok";
    is $ret->comment, "mogefuga", "comment ok";
};


subtest "not exist checklist deleting" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Delete->new(
            database  => $m->database,
            member_id => "6666",
            circle_id => "7777",
        )->run;

        ok !$ret, "no return on not exist checklist";
    } qr/\[INFO\] CHECKLIST_DELETE: circle_id=7777, member_id=6666, count=0/;
};

subtest "exist checklist deleting" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Delete->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => "1122",
        )->run;

        is $ret, 1, "deleted count ok";
    } qr/\[INFO\] CHECKLIST_DELETE: circle_id=1122, member_id=moge, count=1/;
};
