use strict;
use t::Util;
use Test::More tests => 4;
use JSON;

my $m = create_mock_object;

subtest "creating circle" => sub {
    plan tests => 2;
    my $c = $m->run_command(circle_create => {
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
    });

    is $c->id, "77ca48c9876d9e6c2abad3798b589664";
    isa_ok $c, "Hirukara::Database::Row::Circle";
};

subtest "circle not selected" => sub {
    plan tests => 1;
    ok !$m->run_command(circle_single => { circle_id => 'mogemoge' });
};

subtest "creating circle" => sub {
    plan tests => 2;
    my $got = $m->run_command(circle_single => { circle_id => '77ca48c9876d9e6c2abad3798b589664' })->get_columns;
    my $got_serialized = delete $got->{serialized};
    my $got_deserialized = decode_json $got_serialized;

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

        ## system generated
        id            => "77ca48c9876d9e6c2abad3798b589664",

        ## nullable columns
        comment       => undef,
        circle_type   => undef,
    };

    my $nullvalues = {
        'type'          => undef,
        'serial_no'     => undef,
        'color'         => undef,
        'page_no'       => undef,
        'cut_index'     => undef,
        'genre'         => undef,
        'circle_kana'   => undef,
        'publish_info'  => undef,
        'mail'          => undef,
        'remark'        => undef,
        'comment'       => undef,
        'map_x'         => undef,
        'map_y'         => undef,
        'map_layout'    => undef,
        'update_info'   => undef,
        'rss'           => undef,
        'rss_info'      => undef,
    };

    is_deeply $got, $expected, "database value ok";

    delete $expected->{$_} for qw/id circle_type comment/;
    is_deeply $got_deserialized, { %$expected, %$nullvalues }, "serialized value ok";
};

subtest "creating circle with optional args" => sub {
    plan tests => 1;
    my $args = {
        ## required
        comiket_no    => "aaa",
        day           => "bbb",
        circle_sym    => "ccc",
        circle_num    => "ddd",
        circle_flag   => "eee",
        circle_name   => "fff",
        circle_author => "author",
        area          => "area",
        circlems      => "circlems",
        url           => "url",

        ## optional
        type          => "1",
        serial_no     => "2",
        color         => "3",
        page_no       => "4",
        cut_index     => "5",
        genre         => "6",
        circle_kana   => "7",
        publish_info  => "8",
        mail          => "9",
        remark        => "10",
        comment       => "11",
        map_x         => "12",
        map_y         => "13",
        map_layout    => "14",
        update_info   => "15",
        rss           => "16",
        rss_info      => "17",
    };
 
    my $id = $m->run_command(circle_create => $args)->id;
    my $c  = $m->run_command(circle_single => { circle_id => $id });

    my $deserialized = decode_json $c->serialized;
    delete $args->{database};
    is_deeply $deserialized, $args, "create circle with optional args ok";
};
