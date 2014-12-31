use utf8;
use strict;
use t::Util;
use Test::More tests => 5;
use Hirukara::Command::Circle::Create;
use Hirukara::Command::Checklist::Create;
use_ok 'Hirukara::Command::Statistic::Single';

my $m = create_mock_object;

supress_log {
    my $c1 = Hirukara::Command::Circle::Create->new(
        database      => $m->database,
        comiket_no    => "moge1",
        day           => "1",
        circle_sym    => "cc",
        circle_num    => "dd",
        circle_flag   => "ee",
        circle_name   => "name1",
        circle_author => "author",
        area          => "area",
        circlems      => "circlems",
        url           => "url",
    )->run;

    Hirukara::Command::Checklist::Create->new(
        database  => $m->database,
        member_id => $_,
        circle_id => $c1->id,
    )->run for qw/moge fuga piyo/;


    my $c2 = Hirukara::Command::Circle::Create->new(
        database      => $m->database,
        comiket_no    => "moge1",
        day           => "1",
        circle_sym    => "cc",
        circle_num    => "dd",
        circle_flag   => "ee",
        circle_name   => "name2",
        circle_author => "author",
        area          => "area",
        circlems      => "circlems",
        url           => "url",
    )->run;

    Hirukara::Command::Checklist::Create->new(
        database  => $m->database,
        member_id => $_,
        circle_id => $c2->id,
    )->run for qw/moge fuga/;


    my $c3 = Hirukara::Command::Circle::Create->new(
        database      => $m->database,
        comiket_no    => "moge1",
        day           => "3",
        circle_sym    => "cc",
        circle_num    => "dd",
        circle_flag   => "ee",
        circle_name   => "name3",
        circle_author => "author",
        area          => "area",
        circlems      => "circlems",
        url           => "url",
    )->run;

    Hirukara::Command::Checklist::Create->new(
        database  => $m->database,
        member_id => $_,
        circle_id => $c3->id,
    )->run for qw/moge/;
};


subtest "member 'moge' statistic select ok" => sub {
    my $ret = Hirukara::Command::Statistic::Single->new(
        database => $m->database,
        member_id => 'moge',
        exhibition => 'moge1',
    )->run;

    is $ret->all_count,  3, "all_count ok";
    is $ret->day1_count, 2, "day1 count ok";
    is $ret->day2_count, 0, "day2 count ok";
    is $ret->day3_count, 1, "day3 count ok";
};

subtest "member 'fuga' statistic select ok" => sub {
    my $ret = Hirukara::Command::Statistic::Single->new(
        database => $m->database,
        member_id => 'fuga',
        exhibition => 'moge1',
    )->run;

    is $ret->all_count,  2, "all_count ok";
    is $ret->day1_count, 2, "day1 count ok";
    is $ret->day2_count, 0, "day2 count ok";
    is $ret->day3_count, 0, "day3 count ok";
};

subtest "member 'piyo' statistic select ok" => sub {
    my $ret = Hirukara::Command::Statistic::Single->new(
        database => $m->database,
        member_id => 'piyo',
        exhibition => 'moge1',
    )->run;

    is $ret->all_count,  1, "all_count ok";
    is $ret->day1_count, 1, "day1 count ok";
    is $ret->day2_count, 0, "day2 count ok";
    is $ret->day3_count, 0, "day3 count ok";
};

subtest "member 'mogefuga' statistic select ok" => sub {
    my $ret = Hirukara::Command::Statistic::Single->new(
        database => $m->database,
        member_id => 'mogefuga',
        exhibition => 'moge1',
    )->run;

    is $ret->all_count,  0, "all_count ok";
    is $ret->day1_count, 0, "day1 count ok";
    is $ret->day2_count, 0, "day2 count ok";
    is $ret->day3_count, 0, "day3 count ok";
};
