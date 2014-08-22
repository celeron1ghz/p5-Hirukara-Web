use strict;
use t::Util;
use Test::More tests => 21;
use Test::Exception;
use Capture::Tiny 'capture_merged';

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
            serialized    => "json",
            circle_type   => "22",
            comment       => "comment",
        },
    ],
});


## $self->get_checklist
throws_ok { $h->get_checklist() }                 qr/missing mandatory parameter named '\$circle_id'/, "die on no args";
throws_ok { $h->get_checklist(circle_id => "1") } qr/missing mandatory parameter named '\$member_id'/, "die on no args";


## $self->create_checklist
my $out = capture_merged { $h->create_checklist(member_id => "moge", circle_id => "1122") };
my $c1 = $h->get_checklist(member_id => "moge", circle_id => "1122");
is $c1->member_id, "moge", "checklist created";
is $c1->circle_id, "1122", "checklist created";
is $c1->count,     "1",    "checklist created";
like $out, qr/\[INFO\] CREATE_CHECKLIST: member_id=moge, circle_id=1122/, "log message ok";

### not created if same checklist is exist
ok !$h->create_checklist(member_id => "moge", circle_id => "1122"), "undef returned on already exist";


## $self->update_checklist_info
ok !$h->update_checklist_info(member_id => "fuga", circle_id => "9988"), "undef returned on checklist not exist";

### no update
ok !$h->update_checklist_info(member_id => "moge", circle_id => "1122", comment => ""), "undef returned on no update info";

### update comment
my $out2 = capture_merged { $h->update_checklist_info(member_id => "moge", circle_id => "1122", comment => "piyopiyo") };
my $c2 = $h->get_checklist(member_id => "moge", circle_id => "1122");
is $c2->comment, "piyopiyo", "info updated";
is $c2->count, "1", "info updated";
like $out2, qr/\[INFO\] UPDATE_CHECKLIST_COMMENT: checklist_id=1, member_id=moge/;

### specify count to str
throws_ok { $h->update_checklist_info(member_id => "moge", circle_id => "1122", order_count => "a") } qr/'order_count': Validation failed for 'Int' with value a/, "die on type not atch";

### update count
my $out3 = capture_merged { $h->update_checklist_info(member_id => "moge", circle_id => "1122", order_count => 5, comment => "piyoyoyo") };
my $c2 = $h->get_checklist(member_id => "moge", circle_id => "1122");
is $c2->comment, "piyoyoyo", "info updated";
is $c2->count, 5, "info updated";
like $out3, qr/\[INFO\] UPDATE_CHECKLIST_COUNT: checklist_id=1, member_id=moge, before=1, after=5/;


## $self->delete_checklist
ok !$h->delete_checklist(member_id => "moge", circle_id => "3344"), "undef returned on no delete target";
my $out4 = capture_merged { $h->delete_checklist(member_id => "moge", circle_id => "1122") };
like $out4, qr/\[INFO\] DELETE_CHECKLIST: checklist_id=1, member_id=moge, circle_id=1122/;


## $self->delete_all_checklist
throws_ok { $h->delete_all_checklists } qr/missing mandatory parameter named '\$member_id'/, "die on no args";

eval { $h->create_checklist(member_id => "moge", circle_id => $_) } for 1 .. 20;  ## TODO: insert test datto circle. ignore error this is test :-(
eval { $h->create_checklist(member_id => "fuga", circle_id => $_) } for 21 .. 30;
my $cnt;
my $out5 = capture_merged { $cnt = $h->delete_all_checklists(member_id => "moge") };
is $cnt, 20, "delete count ok";
like $out5, qr/\[INFO\] DELETE_ALL_CHECKLIST: member_id=moge, count=20/;
