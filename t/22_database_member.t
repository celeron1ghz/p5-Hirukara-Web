use utf8;
use strict;
use t::Util;
use Test::More tests => 1;
use Hirukara::Database::Row::Member;

subtest "Database::Assignlist->assign_list_label ok" => sub {
    sub member_ok    {
        my($args,$label) = @_;
        my $self = create_object_mock($args);
        local @Plack::Util::Prototype::ISA = 'Hirukara::Database::Row::Member';
        is $self->member_name_label, $label, "member name label is '$label'";
    }

    member_ok { member_name => "moge_name", member_id => "fuga_id" }, "moge_name (fuga_id)";
};
