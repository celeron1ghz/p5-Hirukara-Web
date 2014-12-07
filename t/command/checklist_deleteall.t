use strict;
use t::Util;
use Test::More tests => 4;
use Hirukara::Command::Circle::Create;
use Hirukara::Command::Checklist::Create;
use Hirukara::Command::Checklist::Search;
use_ok "Hirukara::Command::Checklist::Deleteall";

my $m = create_mock_object;

subtest "data create ok" => sub {
    supress_log {
        my @ids = map { Hirukara::Command::Circle::Create->new(
            database      => $m->database,
            comiket_no    => $_,
            day           => "bb",
            circle_sym    => "cc",
            circle_num    => "dd",
            circle_flag   => "ee",
            circle_name   => "ff",
            circle_author => "author",
            area          => "area",
            circlems      => "circlems",
            url           => "url",
        )->run->id } 1 .. 10;

        Hirukara::Command::Checklist::Create->new(database  => $m->database, member_id => "moge", circle_id => $_)->run for @ids[0 .. 4];
        Hirukara::Command::Checklist::Create->new(database  => $m->database, member_id => "fuga", circle_id => $_)->run for @ids[5 .. 8];
    };

    my $ret = Hirukara::Command::Checklist::Search->new(database  => $m->database, where => {})->run;
    is @$ret, 9, "ret count ok";
};

subtest "not deleted on condition not match" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Deleteall->new(database => $m->database, member_id => 'aaaaaa')->run;
        is $ret, 0, "ret count ok";
    } qr/\[INFO\] CHECKLIST_DELETEALL: member_id=aaaaaa, count=0/;
};

subtest "deleted on condition match" => sub {
    output_ok {
        my $ret = Hirukara::Command::Checklist::Deleteall->new(database => $m->database, member_id => 'moge')->run;
        is $ret, 5, "ret count ok";
    } qr/\[INFO\] CHECKLIST_DELETEALL: member_id=moge, count=5/;

    my $ret = Hirukara::Command::Checklist::Search->new(database  => $m->database, where => {})->run;
    is @$ret, 4, "ret count ok";
};
