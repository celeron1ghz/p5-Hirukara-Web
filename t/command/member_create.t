use strict;
use t::Util;
use Test::More tests => 3;
use_ok 'Hirukara::Command::Member::Create';

my $m = create_mock_object;

subtest "member create ok" => sub {
    output_ok {
        my $ret = Hirukara::Command::Member::Create->new(
            database => $m->database,
            id           => '11223344',
            member_id    => 'mogemoge',
            display_name => 'display_name',
            image_url    => 'image_url',
        )->run;

        ok $ret, "object returned on member create ok";
        isa_ok $ret, "Hirukara::Database::Row::Member";

    } qr/\[INFO\] MEMBER_CREATE: id=11223344, member_id=mogemoge/;

    my $ret = $m->database->single(member => { id => 11223344 });
    ok $ret, "member exist";
    is $ret->id,           '11223344',     'id ok';
    is $ret->member_id,    'mogemoge',     'member_id ok';
    is $ret->display_name, 'display_name', 'display_name ok';
    is $ret->image_url,    'image_url',    'image_url ok';
};


subtest "member already exist" => sub {
    output_ok {
        my $ret = Hirukara::Command::Member::Create->new(
            database => $m->database,
            id           => '11223344',
            member_id    => 'mogemoge',
            display_name => 'display_name',
            image_url    => 'image_url',
        )->run;

        ok !$ret, "nothing returned on member exists";

    } qr/\[INFO\] MEMBER_EXISTS: member_id=mogemoge/;
};

