use strict;
use t::Util;
use Test::More tests => 6;
use Hirukara::Command::Circle::Single;
use Hirukara::Command::Circle::Create;
use_ok 'Hirukara::Command::Circle::Update';

my $m = create_mock_object;
my $ID;

subtest "creating circle first" => sub {
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

    my $c2 = Hirukara::Command::Circle::Single->new(database => $m->database, circle_id => $ID)->run;
    is $c2->circle_type, undef, "circle_type ok";
    is $c2->comment,     undef, "comment ok";
};

subtest "not updating" => sub {
    output_ok {
        my $ret = Hirukara::Command::Circle::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
        )->run;
    } qr/^$/;

    my $c = Hirukara::Command::Circle::Single->new(database => $m->database, circle_id => $ID)->run;
    is $c->circle_type, undef, "circle_type ok";
    is $c->comment,     undef, "comment ok";
};


subtest "updating both" => sub {
    output_ok {
        my $ret = Hirukara::Command::Circle::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
            circle_type => 3344,
            comment => "mogemogefugafuga"
        )->run;
    } qr/\[INFO\] CIRCLE_TYPE_UPDATE: circle_id=77ca48c9876d9e6c2abad3798b589664, circle_name=ff, member_id=moge, before_type=, after_type=3344/,
      qr/\[INFO\] CIRCLE_COMMENT_UPDATE: circle_id=77ca48c9876d9e6c2abad3798b589664, circle_name=ff, member_id=moge/;


    my $c = Hirukara::Command::Circle::Single->new(database => $m->database, circle_id => $ID)->run;
    is $c->circle_type, "3344", "circle_type ok";
    is $c->comment,     "mogemogefugafuga", "comment ok";
};

subtest "updating circle_type" => sub {
    output_ok {
        my $ret = Hirukara::Command::Circle::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
            circle_type => 9999,
        )->run;
    } qr/\[INFO\] CIRCLE_TYPE_UPDATE: circle_id=77ca48c9876d9e6c2abad3798b589664, circle_name=ff, member_id=moge, before_type=3344, after_type=9999/;

    my $c = Hirukara::Command::Circle::Single->new(database => $m->database, circle_id => $ID)->run;
    is $c->circle_type, "9999", "circle_type ok";
    is $c->comment,     "mogemogefugafuga", "comment ok";
};

subtest "updating circle_type" => sub {
    output_ok {
        my $ret = Hirukara::Command::Circle::Update->new(
            database  => $m->database,
            member_id => "moge",
            circle_id => $ID,
            comment   => "piyopiyo",
        )->run;
    } qr/\[INFO\] CIRCLE_COMMENT_UPDATE: circle_id=77ca48c9876d9e6c2abad3798b589664, circle_name=ff, member_id=moge/;

    my $c = Hirukara::Command::Circle::Single->new(database => $m->database, circle_id => $ID)->run;
    is $c->circle_type, "9999", "circle_type ok";
    is $c->comment,     "piyopiyo", "comment ok";
};
