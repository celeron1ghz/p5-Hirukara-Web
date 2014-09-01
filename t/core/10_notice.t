use strict;
use t::Util;
use Test::More tests => 15;
use Test::Exception;
use Capture::Tiny 'capture_merged';

my $h = create_mock_object;
$h->database->load_plugin("Count");

ok !$h->get_notice, "nothing return on no notice";
is $h->database->count("notice"), 0, "notice not exist";


## $self->update_notice
throws_ok { $h->update_notice } qr/missing mandatory parameter named '\$member_id'/, "die on no args";
throws_ok { $h->update_notice(member_id => undef)  } qr/'member_id': Validation failed for 'Str' with value undef/, "die on no args";
throws_ok { $h->update_notice(member_id => '1122') } qr/missing mandatory parameter named '\$text'/, "die on no args";
throws_ok { $h->update_notice(member_id => '1122', text => undef) } qr/'text': Validation failed for 'Str' with value undef/, "die on no args";
my $ret;
my $out = capture_merged {
    $ret = $h->update_notice(member_id => "1133", text => "mogemoge"), "object returned";
};

like $out, qr/\[INFO\] UPDATE_NOTICE: member_id=1133/, "log message ok";
is $ret->id,        1,      "id ok";
is $ret->member_id, "1133", "member_id ok";
is $ret->text,      "mogemoge", "member_id ok";

capture_merged { $h->update_notice(member_id => $_, text => "mogemoge$_"), "object returned" for qw/1144 1155 1166/ };
is $h->database->count("notice"), 4, "notice not exist";
ok my $ret2 = $h->get_notice, "notice get ok";
is $ret2->id,        4,              "most recent notice got";
is $ret2->member_id, "1166",         "most recent member_id got";
is $ret2->text,      "mogemoge1166", "most recent text got";
