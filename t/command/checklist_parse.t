use utf8;
use strict;
use t::Util;
use Test::More tests => 5;
use Test::Exception;
use Hirukara::Command::Checklist::Create;
use_ok 'Hirukara::Command::Checklist::Parse';

my $m    = create_mock_object;
my $ID   = 'bde6eff32e4a3c9b8251329fbb6aedb9';
my $CHK1 = make_temporary_file(<<EOT);
Header,a,ComicMarket86,utf8,source
Circle,2,3,4,5,金,7,Ａ,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
EOT

my $CHK2 = make_temporary_file(<<EOT);
Header,a,ComicMarket86,utf8,source
EOT

subtest "die on comiket_no and exhibition is not match" => sub {
    output_ok {
        throws_ok {
            Hirukara::Command::Checklist::Parse->new(
                exhibition => 'ComicMarket99',
                database  => $m->database,
                member_id => 'moge',
                csv_file  => $CHK1,
            )->run;
        } "Hirukara::CSV::ExhibitionNotMatchException";
    } qr/^$/;
};

subtest "new circle created" => sub {
    plan tests => 13;

    is $m->database->count('circle'),    0, "circle count ok";
    is $m->database->count('checklist'), 0, "checklist count ok";

    my $ret;

    output_ok {
        $ret = Hirukara::Command::Checklist::Parse->new(
            exhibition => 'ComicMarket86',
            database  => $m->database,
            member_id => 'moge',
            csv_file  => $CHK1,
        )->run;
    } qr/\[INFO\] CIRCLE_CREATE: name=11, author=13/
     ,qr/\[INFO\] CHECKLIST_PARSE: member_id=moge, exhibition=ComicMarket86, checklist=1, database=0, exist=0, create=1, delete=0/;
 
    my $res = $ret->merge_results;
    is_deeply $res->{delete}, {}, "delete is empty";
    is_deeply $res->{exist},  {}, "exist is empty";
    is_deeply [keys %{$res->{create}}], [$ID], "create is not empty";

    is $m->database->count('circle'),    1, "circle count ok";
    is $m->database->count('checklist'), 0, "checklist count ok";

    ok my $circle = $m->database->single(circle => { id => $ID }), "circle created";
    is $circle->circle_name,   "11", "circle_name ok";
    is $circle->circle_author, "13", "circle_author ok";

    actionlog_ok $m;
};

supress_log {
    Hirukara::Command::Checklist::Create->new(
        exhibition => 'ComicMarket86',
        database  => $m->database,
        circle_id => $ID,
        member_id => 'moge',
    )->run;
};

subtest "return structure check of 'exist'" => sub {
    plan tests => 9;

    is $m->database->count('circle'),    1, "circle count ok";
    is $m->database->count('checklist'), 1, "checklist count ok";

    my $ret;

    output_ok {
        $ret = Hirukara::Command::Checklist::Parse->new(
            exhibition => 'ComicMarket86',
            database  => $m->database,
            member_id => 'moge',
            csv_file  => $CHK1,
        )->run;
    } qr/\[INFO\] CHECKLIST_PARSE: member_id=moge, exhibition=ComicMarket86, checklist=1, database=1, exist=1, create=0, delete=0/;
 
    my $res = $ret->merge_results;
    is_deeply $res->{create}, {},  "create is empty";
    is_deeply $res->{delete},  {}, "delete is empty";
    is_deeply [keys %{$res->{exist}}], [$ID], "exist is not empty";

    is $m->database->count('circle'),    1, "circle count ok";
    is $m->database->count('checklist'), 1, "checklist count ok";

    actionlog_ok $m
        , { type => "チェックの追加", message => "moge さんが '11' を追加しました" };
};

subtest "new circle not created because already exist" => sub {
    plan tests => 9;

    is $m->database->count('circle'),    1, "circle count ok";
    is $m->database->count('checklist'), 1, "checklist count ok";

    my $ret;

    output_ok {
        $ret = Hirukara::Command::Checklist::Parse->new(
            exhibition => 'ComicMarket86',
            database  => $m->database,
            member_id => 'moge',
            csv_file  => $CHK2,
        )->run;
    } qr/\[INFO\] CHECKLIST_PARSE: member_id=moge, exhibition=ComicMarket86, checklist=0, database=1, exist=0, create=0, delete=1/;
 
    my $res = $ret->merge_results;
    is_deeply $res->{create}, {}, "create is empty";
    is_deeply $res->{exist},  {}, "exist is empty";
    is_deeply [keys %{$res->{delete}}], [$ID], "delete is not empty";

    is $m->database->count('circle'),    1, "circle count ok";
    is $m->database->count('checklist'), 1, "checklist count ok";

    actionlog_ok $m
        , { type => "チェックの追加", message => "moge さんが '11' を追加しました" };
};
