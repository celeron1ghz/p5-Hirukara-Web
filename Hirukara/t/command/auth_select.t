use strict;
use t::Util;
use Test::More tests => 6;

my $m = create_mock_object;

## test data creating...
supress_log {
    $m->run_command('auth.create' => { member_id => 'moge', role_type => $_ }) for qw/aa bb cc dd ee/;
};

subtest "single select found" => sub {
    plan tests => 4;
    my $ret = $m->run_command('auth.single' => { member_id => 'moge', role_type => 'aa' });
    ok $ret, "auth returned";
    isa_ok $ret, "Hirukara::DB::Row::MemberRole";

    is $ret->member_id, "moge", "member_id ok";
    is $ret->role_type, "aa",   "role_type ok";
};

subtest "single select not found" => sub {
    plan tests => 1;
    my $ret = $m->run_command('auth.single' => { member_id => 'moge', role_type => 'mogemoge' });
    ok !$ret, "auth not returned";
};


subtest "member_id only search" => sub {
    plan tests => 5;
    my $ret = $m->run_command('auth.select' => { member_id => 'moge' });
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    my @ret = $ret->all;
    is scalar @ret, 5, "result returned";
    is_deeply [ map { $_->member_id } @ret ], [ qw/moge moge moge moge moge/ ], "member_id ok";
    is_deeply [ map { $_->role_type } @ret ], [ qw/aa bb cc dd ee/ ], "role_type ok";
};


subtest "role_type only search" => sub {
    plan tests => 5;
    my $ret = $m->run_command('auth.select' => { role_type => 'cc' });
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    my @ret = $ret->all;
    is scalar @ret, 1, "result returned";
    is $ret[0]->member_id, 'moge', "member_id ok";
    is $ret[0]->role_type, 'cc', "role_type ok";
};


subtest "member_id and role_type search and found" => sub {
    plan tests => 5;
    my $ret = $m->run_command('auth.select' => { member_id => 'moge', role_type => 'cc' });
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    my @ret = $ret->all;
    is scalar @ret, 1, "result returned";
    is $ret[0]->member_id, 'moge', "member_id ok";
    is $ret[0]->role_type, 'cc', "role_type ok";
};


subtest "member_id and role_type search and not found" => sub {
    plan tests => 3;
    my $ret = $m->run_command('auth.select' => { member_id => 'mogemoge', role_type => 'fugafuga' });
    ok $ret, "iterator returned";
    isa_ok $ret, "Teng::Iterator";

    is scalar @{$ret->all}, 0, "no result returned";
};
