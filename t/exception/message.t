use strict;
use warnings;
use Test::More;
use Test::Exception tests => 1;
use Encode;
use Hirukara::Exception;

sub message_ok (&@) {
    my $code = shift;
    my $re = shift;
    local $@;
    eval { $code->() };
    like encode_utf8($@->as_string), $re, "exception message ok";
}

message_ok { Hirukara::CSV::ExhibitionNotMatchException->throw(given_exhibition => 'given', want_exhibition => 'want') }
    qr/アップロードされたCSVファイルは'given'のCSVですが、現在受け付けているのは'want'のCSVです。/;
