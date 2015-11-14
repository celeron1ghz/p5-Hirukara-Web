use utf8;
use strict;
use t::Util;
use Test::More tests => 1;
use Encode;
use Hirukara::DB::Row::AssignList;

subtest "DB::Assignlist->assign_list_label ok" => sub {
    sub assignlist_ok    {
        my($args,$label) = @_;
        my $self = create_object_mock($args);
        local @Plack::Util::Prototype::ISA = 'Hirukara::DB::Row::AssignList';
        is $self->assign_list_label, $label, "assignlist label is '$label'";
    }

    plan tests => 3;
    my $NAME;
    local *Hirukara::DB::Row::AssignList::get_columns = sub { +{ member_name => $NAME } };

    $NAME = 'もげ';
    assignlist_ok { name => "moge list", member_id => "fuga" }, "moge list [もげ]";

    $NAME = undef;
    assignlist_ok { name => "moge list", member_id => "fuga" }, "moge list [fuga]";

    assignlist_ok { name => "moge list", member_id => undef },  "moge list [未割当]";
};
