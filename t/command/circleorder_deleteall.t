use utf8;
use strict;
use t::Util;
use Test::More tests => 3;

my $m = create_mock_object;

subtest "data create ok" => sub {
    plan tests => 3;
    ## Moge1 circles
    my @ids1 = map { create_mock_circle($m, circle_name => "circle $_",  comiket_no => "Moge11")->id } 1  .. 10;
    $m->run_command('circle_order.update' => { book_id => $_, count => 1, member_id => "moge" }) for 1,2,3,4;
    $m->run_command('circle_order.update' => { book_id => $_, count => 1, member_id => "fuga" }) for 5,6,7,8,9;

    ## Moge22 circles
    my @ids2 = map { create_mock_circle($m, circle_name => "circle $_!", comiket_no => "Moge22")->id } 11 .. 20;
    $m->run_command('circle_order.update' => { book_id => $_, count => 1, member_id => "piyo" }) for 11, 12;

    record_count_ok $m, { circle => 20, circle_book => 20, circle_order => 11 };

    is $m->db->count(circle_order => undef, { member_id => 'moge' }), 4;
    is $m->db->count(circle_order => undef, { member_id => 'fuga' }), 5;
    delete_cached_log $m;
};

subtest "ok on cirlce_order record not found" => sub {
    plan tests => 4;
    local $m->{exhibition} = 'fugafuga';
    my $ret = $m->run_command('circle_order.delete_all' => { member_id => 'mogemoge' });
    is $ret, "0", "ret count ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'mogemoge',
        message_id => '発注を全削除しました。 (member_id=mogemoge, exhibition=fugafuga, count=)',
        parameters => '["発注を全削除しました。","member_id","mogemoge","exhibition","fugafuga","count",0]',
    };

    record_count_ok $m, { circle => 20, circle_book => 20, circle_order => 11 };
};

subtest "ok on cirlce_order record not found" => sub {
    plan tests => 3;
    local $m->{exhibition} = 'Moge11';
    my $ret = $m->run_command('circle_order.delete_all' => { member_id => 'moge' });
    is $ret, 4, "ret count ok";

    test_actionlog_ok $m, {
        id         => 1,
        circle_id  => undef,
        member_id  => 'moge',
        message_id => '発注を全削除しました。 (member_id=moge, exhibition=Moge11, count=4)',
        parameters => '["発注を全削除しました。","member_id","moge","exhibition","Moge11","count","4"]',
    };

    record_count_ok $m, { circle => 20, circle_book => 20, circle_order => 7 };
};
