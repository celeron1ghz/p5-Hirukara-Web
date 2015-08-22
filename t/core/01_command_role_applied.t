use strict;
use Test::More tests => 1;
use Hirukara;

my @command_classes = qw/
   Hirukara::Command::Actionlog::Create
   Hirukara::Command::Actionlog::Select
   Hirukara::Command::Assign::Create
   Hirukara::Command::Assign::Search
   Hirukara::Command::Assignlist::Create
   Hirukara::Command::Assignlist::Single
   Hirukara::Command::Assignlist::Update
   Hirukara::Command::Auth::Create
   Hirukara::Command::Auth::Select
   Hirukara::Command::Auth::Single
   Hirukara::Command::Checklist::BulkOperation
   Hirukara::Command::Checklist::Create
   Hirukara::Command::Checklist::Delete
   Hirukara::Command::Checklist::DeleteAll
   Hirukara::Command::Checklist::Export
   Hirukara::Command::Checklist::BulkExport
   Hirukara::Command::Checklist::Joined
   Hirukara::Command::Checklist::Parse
   Hirukara::Command::Checklist::Search
   Hirukara::Command::Checklist::Single
   Hirukara::Command::Checklist::Update
   Hirukara::Command::Circle::Create
   Hirukara::Command::Circle::Search
   Hirukara::Command::Circle::Single
   Hirukara::Command::Circle::Update
   Hirukara::Command::Circletype::Search
   Hirukara::Command::Circletype::Create
   Hirukara::Command::Member::Create
   Hirukara::Command::Member::Select
   Hirukara::Command::Member::Update
   Hirukara::Command::Notice::Select
   Hirukara::Command::Notice::Single
   Hirukara::Command::Notice::Update
   Hirukara::Command::Statistic::Select
   Hirukara::Command::Statistic::Single
   Hirukara::Command::Noncomiket::Createcircle
/;

is_deeply
    { map { $_ => 1 } Hirukara->get_all_command_object },
    { map { $_ => 1 } @command_classes },
    "command class listing ok";
