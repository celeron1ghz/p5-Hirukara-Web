use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use JSON;

my $m = create_mock_object;
my $ID;

subtest "creating circle" => sub {
    plan tests => 5;
    my $c = $m->run_command('circle.create' => {
        comiket_no    => "aa",
        day           => "bb",
        circle_sym    => "Ａ",
        circle_num    => "01",
        circle_flag   => "a",
        circle_name   => "ff",
        circle_author => "author",
        area          => "area",
        circlems      => "circlems",
        url           => "url",
        circle_type   => 0,
    });

    $ID = $c->id;
    is $c->id, "d8fa44ae94878d44110be83a94334cd6";
    isa_ok $c, "Hirukara::Database::Row::Circle";
    record_count_ok $m, { circle => 1, circle_book => 1 };
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $c->id,
        member_id  => undef,
        message_id => 'サークルを作成しました。: [aa] ff / author',
        parameters => '["サークルを作成しました。","circle_id","d8fa44ae94878d44110be83a94334cd6"]',
    }, {
        id         => 2,
        circle_id  => $c->id,
        member_id  => 'hirukara',
        message_id => '本を追加しました。: [aa] ff / author (id=1, book_name=新刊セット, comment=, member_id=hirukara)',
        parameters => '["本を追加しました。","circle_id","d8fa44ae94878d44110be83a94334cd6","id","1","book_name","新刊セット","comment",null,"member_id","hirukara"]',
    };
};

subtest "circle not selected" => sub {
    plan tests => 1;
    ok !$m->run_command('circle.single' => { circle_id => 'mogemoge' });
};

subtest "creating circle" => sub {
    plan tests => 2;
    my $got = $m->run_command('circle.single' => { circle_id => $ID })->get_columns;
    my $got_serialized = delete $got->{serialized};
    my $got_deserialized = decode_json $got_serialized;

    my $expected = {
        comiket_no    => "aa",
        day           => "bb",
        circle_sym    => "Ａ",
        circle_num    => "01",
        circle_flag   => "a",
        circle_name   => "ff",
        circle_author => "author",
        area          => "東1壁",
        circlems      => "circlems",
        url           => "url",
        circle_type   => 0,
        circle_point  => 10,

        ## system generated
        id            => $ID,

        ## nullable columns
        comment       => undef,
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

    delete $expected->{$_} for qw/id comment/;
    ## undef is input value, 0 is db's default value.
    ## serializing at before db insert, so serialized circle_point is 0
    is_deeply $got_deserialized, { %$expected, %$nullvalues, circle_point => undef, area => 'area' }, "serialized value ok";
};

subtest "creating circle with optional args" => sub {
    plan tests => 4;
    my $args = {
        ## required
        comiket_no    => "aaa",
        day           => "bbb",
        circle_sym    => "Ａ",
        circle_num    => "01",
        circle_flag   => "a",
        circle_name   => "fff",
        circle_author => "author",
        area          => "area",
        circlems      => "circlems",
        url           => "url",
        circle_type   => 0,
        circle_point  => 0,

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
 
    my $id = $m->run_command('circle.create' => $args)->id;
    my $c  = $m->run_command('circle.single' => { circle_id => $id });

    my $deserialized = decode_json $c->serialized;
    delete $args->{database};
    is_deeply $deserialized, $args, "create circle with optional args ok";
    record_count_ok $m, { circle => 2, circle_book => 2 };
    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => $c->id,
        member_id  => undef,
        message_id => 'サークルを作成しました。: [aaa] fff / author',
        parameters => '["サークルを作成しました。","circle_id","5aae472ff20202e193c4bed8ceefc0c5"]',
    }, {
        id         => 2,
        circle_id  => $c->id,
        member_id  => 'hirukara',
        message_id => '本を追加しました。: [aaa] fff / author (id=2, book_name=新刊セット, comment=, member_id=hirukara)',
        parameters => '["本を追加しました。","circle_id","5aae472ff20202e193c4bed8ceefc0c5","id","2","book_name","新刊セット","comment",null,"member_id","hirukara"]',
    };
};
