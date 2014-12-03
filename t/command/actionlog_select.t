use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use_ok 'Hirukara::Command::Actionlog::Select';

my $m = create_mock_object;

## TODO: insert method
$m->database->insert(action_log => { message_id => "MEMBER_CREATE", parameters => qq/{"member_name":"$_"}/ }) for 1 .. 128;

subtest "all rows return on specify count=0" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, count => 0)->run;
    is scalar @$ret, 128, "return count ok";
};


subtest "single actionlog test" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, count => 1)->run;
    is scalar @$ret, 1, "return count ok";
    is_deeply $ret, [{ message => '128 さんが初めてログインしました', type => 'メンバーの新規ログイン' }], "data ok";
};


subtest "getting specify count actionlog test" => sub {
    my $ret = Hirukara::Command::Actionlog::Select->new(database => $m->database, count => 20)->run;
    is scalar @$ret, 20, "return count ok";
};
