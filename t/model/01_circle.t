use strict;
use t::Util;
use Test::More tests => 16;
use Test::Exception;
use Hirukara::Model::Circle;

my $o = create_model_mock('Hirukara::Model::Circle');

insert_data($o, {
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
            serialized    => "json",
            circle_type   => "22",
            comment       => "comment",
            circle_type   => 22,
        },
    ],
});

## $self->get_circle_by_id
throws_ok { $o->get_circle_by_id } qr/missing mandatory parameter named '\$id'/, "die on no args";
throws_ok { $o->get_circle_by_id(id => undef) } qr/'id': Validation failed for 'Str' with value undef/, "die on no args";
throws_ok { $o->get_circle_by_id(id => [])    } qr/'id': Validation failed for 'Str' with value ARRAY/, "die on no args";
ok !$o->get_circle_by_id(id => "1111"), "object not returned";
ok  $o->get_circle_by_id(id => "1122"), "object returned";

## $self->update_circle_info
throws_ok { $o->update_circle_info(member_id => "moge") } qr/missing mandatory parameter named '\$circle_id'/, "die on no args";
throws_ok { $o->update_circle_info(member_id => "moge", circle_id => undef) } qr/'circle_id': Validation failed for 'Str' with value undef/, "die on no args";
ok !$o->update_circle_info(member_id => "moge", circle_id => "11122222"), "undef returned on not exist circle";

### not updating both
ok !$o->update_circle_info(member_id => "moge", circle_id => "1122", circle_type => 22, comment => "comment"), "undef returned on not exist circle";
my $c1 = $o->get_circle_by_id(id => "1122");
is $c1->circle_type, "22", "original data not changed";
is $c1->comment,     "comment", "original data not changed";

### updating both
my $out = capture_merged {
    ok $o->update_circle_info(member_id => "moge", circle_id => "1122", circle_type => 3344, comment => "mogemogefugafuga"), "something returned on success update";
};

like $out, qr/\[INFO\] UPDATE_CIRCLE_TYPE: circle_id=1122, before=22, after=3344/, "log message ok";
like $out, qr/\[INFO\] UPDATE_CIRCLE_COMMENT: circle_id=1122/,                     "log message ok";

my $c2 = $o->get_circle_by_id(id => "1122");
is $c2->circle_type, "3344", "original data changed";
is $c2->comment,     "mogemogefugafuga", "original data changed";

