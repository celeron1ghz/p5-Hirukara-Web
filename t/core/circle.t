use strict;
use t::Util;
use Test::More tests => 5;
use Test::Exception;

my $h = create_mock_object;

insert_data($h,{
    circle => [
        {
            id            => '1122',
            comiket_no    => 33,
            area          => 'area',
            day           => 2,
            circle_sym    => 'A',
            circle_num    => 11,
            circle_flag   => 'a',
            circle_name   => 'name',
            circle_author => 'author',
            circlems      => "ms",
            url           => "url",
            serialized    => "json"
        },
    ],
});

throws_ok { $h->get_circle_by_id } qr/missing mandatory parameter named '\$id'/, "die on no args";
throws_ok { $h->get_circle_by_id(id => undef) } qr/'id': Validation failed for 'Str' with value undef/, "die on no args";
throws_ok { $h->get_circle_by_id(id => [])    } qr/'id': Validation failed for 'Str' with value ARRAY/, "die on no args";
ok !$h->get_circle_by_id(id => "1111"), "object not returned";
ok  $h->get_circle_by_id(id => "1122"), "object returned";
