use strict;
use t::Util;
use Test::More tests => 9;
use Hirukara::Command::Assignlist::Create;
use Hirukara::Command::Assignlist::Single;
use_ok 'Hirukara::Command::Assign::Search';
use_ok 'Hirukara::Command::Assign::Create';

my $m = create_mock_object;

supress_log {
    Hirukara::Command::Assignlist::Create->new(database => $m->database, exhibition => 'moge', member_id => "foo")->run;
    Hirukara::Command::Assignlist::Create->new(database => $m->database, exhibition => 'fuga', member_id => "bar")->run;
};

my $list = Hirukara::Command::Assignlist::Single->new(database => $m->database, id => 1)->run;


subtest "create success on empty circle_ids" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assign::Create->new(
            database   => $m->database,
            assign_list_id => $list->id,
            circle_ids     => [],
        )->run;

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 0, "empty array returned";

    } qr/\[INFO\] ASSIGN_CREATE: assign_list_id=1, created_assign=0, exist_assign=0/;

    actionlog_ok $m;
};


subtest "create success on only new circle_ids" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assign::Create->new(
            database   => $m->database,
            assign_list_id => $list->id,
            circle_ids     => [ 1,2,3,4,5 ],
        )->run;

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 5, "empty array returned";

    } qr/\[INFO\] ASSIGN_CREATE: assign_list_id=1, created_assign=5, exist_assign=0/;

    actionlog_ok $m;
};


subtest "create success on new and exist circle_ids" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assign::Create->new(
            database   => $m->database,
            assign_list_id => $list->id,
            circle_ids     => [ 1,2,7,8,9 ],
        )->run;

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 3, "empty array returned";

    } qr/\[INFO\] ASSIGN_CREATE: assign_list_id=1, created_assign=3, exist_assign=2/;

    actionlog_ok $m;
};


subtest "create success on only exist circle_ids" => sub {
    output_ok {
        my $ret = Hirukara::Command::Assign::Create->new(
            database   => $m->database,
            assign_list_id => $list->id,
            circle_ids     => [ 1,2,3,4,5,7,8,9 ],
        )->run;

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "ARRAY";
        is @$ret, 0, "empty array returned";

    } qr/\[INFO\] ASSIGN_CREATE: assign_list_id=1, created_assign=0, exist_assign=8/;

    actionlog_ok $m;
};


subtest "select assign ok" => sub {
    my @ret = Hirukara::Command::Assign::Search->new(database => $m->database)->run->all;
    is @ret, 2, "return count ok";

    my $a1 = $ret[0];
    is $a1->id,    1, "id ok";
    is $a1->count, 8, "assign count ok";

    my $a2 = $ret[1];
    is $a2->id,    2, "id ok";
    is $a2->count, 0, "assign count ok";
};


subtest "exhibition specified select ok" => sub {
    my @ret = Hirukara::Command::Assign::Search->new(database => $m->database, exhibition => 'moge')->run->all;
    is @ret, 1, "return count ok";

    my $a1 = $ret[0];
    is $a1->id,    1, "id ok";
    is $a1->count, 8, "assign count ok";
};


subtest "member_id specified select ok" => sub {
    my @ret = Hirukara::Command::Assign::Search->new(database => $m->database, member_id => 'foo')->run->all;
    is @ret, 1, "return count ok";

    my $a1 = $ret[0];
    is $a1->id,    1, "id ok";
    is $a1->count, 8, "assign count ok";
};
