use strict;
use t::Util;
use Test::More tests => 4;
use Hirukara::Command::Notice::Update;
use_ok 'Hirukara::Command::Notice::Select';

my $m = create_mock_object;

supress_log {
    Hirukara::Command::Notice::Update->new(database => $m->database, member_id => 'mogemoge', text => 'fugafuga')->run;
};

subtest "first notice select ok" => sub {
    my $ret = Hirukara::Command::Notice::Select->new(database => $m->database)->run;
    ok $ret, "object returned on auth create ok";
    isa_ok $ret, "Hirukara::Database::Row::Notice";

    is $ret->id,        '1',        'id ok';
    is $ret->member_id, 'mogemoge', 'member_id ok';
    is $ret->text,      'fugafuga', 'text ok';
};


supress_log {
    Hirukara::Command::Notice::Update->new(database => $m->database, member_id => 'fugafuga', text => 'piyopiyo')->run;
};

subtest "first notice select ok" => sub {
    my $ret = Hirukara::Command::Notice::Select->new(database => $m->database)->run;
    ok $ret, "object returned on auth create ok";
    isa_ok $ret, "Hirukara::Database::Row::Notice";

    is $ret->id,        '2',        'id ok';
    is $ret->member_id, 'fugafuga', 'member_id ok';
    is $ret->text,      'piyopiyo', 'text ok';
};


supress_log {
    Hirukara::Command::Notice::Update->new(database => $m->database, member_id => '112233', text => '123456')->run;
    Hirukara::Command::Notice::Update->new(database => $m->database, member_id => '445566', text => '234567')->run;
};

subtest "first notice select ok" => sub {
    my $ret = Hirukara::Command::Notice::Select->new(database => $m->database)->run;
    ok $ret, "object returned on auth create ok";
    isa_ok $ret, "Hirukara::Database::Row::Notice";

    is $ret->id,        '4',      'id ok';
    is $ret->member_id, '445566', 'member_id ok';
    is $ret->text,      '234567', 'text ok';
};

