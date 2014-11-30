use strict;
use utf8;
use Hirukara::Model::ActionLog;
use Test::More tests => 4;
use Test::Exception;
use Plack::Util;

sub object {
    my $param = shift;
    my $obj = {};

    while ( my($k,$v) = each %$param )  {
        $obj->{$k} = sub { $v };
    }

    return Plack::Util::inline_object(%$obj);
}

sub test_log {
    my($args,$expected) = @_;
    my $obj = object($args);
    my $got = Hirukara::Model::ActionLog->extract_log($obj);
    is_deeply $got, $expected, "log extract ok";
}

throws_ok { Hirukara::Model::ActionLog->extract_log } qr/log object not specified/, "die on no args";

throws_ok { Hirukara::Model::ActionLog->extract_log( object({ message_id => 'aaaaaa' }) ) } qr/unknown message id 'aaaaaa'/, "die on no message";

test_log { message_id => 'CHECKLIST_CREATE', parameters => '{"member_id":1234}' }
        => { message => "1234 さんが '' を追加しました", type => "チェックの追加" };

test_log { message_id => 'CHECKLIST_CREATE', parameters => '{"member_id":1234,"circle_name":5678}' }
        => { message => "1234 さんが '5678' を追加しました", type => "チェックの追加" };
