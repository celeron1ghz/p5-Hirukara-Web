use strict;
use t::Util;
use Test::More tests => 5;
use Hirukara::Command::Auth::Create;
use_ok 'Hirukara::Command::Auth::Select';

my $m = create_mock_object;

## test data creating...
supress_log {
    Hirukara::Command::Auth::Create->new(database => $m->database, member_id => 'moge', role_type => $_)->run for qw/aa bb cc dd ee/;
};

subtest "member_id only search" => sub {
    my $ret = Hirukara::Command::Auth::Select->new(database => $m->database, member_id => 'moge')->run;
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    my @ret = $ret->all;
    is scalar @ret, 5, "result returned";
    is_deeply [ map { $_->member_id } @ret ], [ qw/moge moge moge moge moge/ ], "member_id ok";
    is_deeply [ map { $_->role_type } @ret ], [ qw/aa bb cc dd ee/ ], "role_type ok";
};


subtest "role_type only search" => sub {
    my $ret = Hirukara::Command::Auth::Select->new(database => $m->database, role_type => 'cc')->run;
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    my @ret = $ret->all;
    is scalar @ret, 1, "result returned";
    is $ret[0]->member_id, 'moge', "member_id ok";
    is $ret[0]->role_type, 'cc', "role_type ok";
};


subtest "member_id and role_type search and found" => sub {
    my $ret = Hirukara::Command::Auth::Select->new(database => $m->database, member_id => 'moge', role_type => 'cc')->run;
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    my @ret = $ret->all;
    is scalar @ret, 1, "result returned";
    is $ret[0]->member_id, 'moge', "member_id ok";
    is $ret[0]->role_type, 'cc', "role_type ok";
};


subtest "member_id and role_type search and not found" => sub {
    my $ret = Hirukara::Command::Auth::Select->new(database => $m->database, member_id => 'mogemoge', role_type => 'fugafuga')->run;
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    is scalar @{$ret->all}, 0, "no result returned";
};
