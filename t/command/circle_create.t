use strict;
use t::Util;
use Test::More tests => 5;
use_ok 'Hirukara::Command::Circle::Create';
use_ok 'Hirukara::Command::Circle::Single';

my $m = create_mock_object;

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
        serialized    => "serialized",
    )->run;

    is $c->id, "77ca48c9876d9e6c2abad3798b589664";
    isa_ok $c, "Hirukara::Database::Row::Circle";
};

subtest "circle not selected" => sub {
    ok !Hirukara::Command::Circle::Single->new(database => $m->database, circle_id => 'mogemoge')->run, "circle not found";
};

subtest "creating circle" => sub {
    my $got = Hirukara::Command::Circle::Single->new(database => $m->database, circle_id => '77ca48c9876d9e6c2abad3798b589664')->run;

    my $expected = {
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
        serialized    => "serialized",

        ## system generated
        id            => "77ca48c9876d9e6c2abad3798b589664",

        ## nullable columns
        comment       => undef,
        circle_type   => undef,
    };

    is_deeply $got->get_columns, $expected;
};
