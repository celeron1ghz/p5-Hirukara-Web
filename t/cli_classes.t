use strict;
use Test::More tests => 1;
use Hirukara::CLI;

is_deeply [ Hirukara::CLI->get_all_command_object ],[ qw/
   Hirukara::Command::Actionlog::Select
   Hirukara::Command::Assign::Create
   Hirukara::Command::Assign::Search
   Hirukara::Command::Assignlist::Create
   Hirukara::Command::Assignlist::Single
   Hirukara::Command::Assignlist::Update
   Hirukara::Command::Auth::Create
   Hirukara::Command::Auth::Select
   Hirukara::Command::Checklist::Create
   Hirukara::Command::Checklist::Delete
   Hirukara::Command::Checklist::Deleteall
   Hirukara::Command::Checklist::Export
   Hirukara::Command::Checklist::Joined
   Hirukara::Command::Checklist::Merge
   Hirukara::Command::Checklist::Single
   Hirukara::Command::Checklist::Update
   Hirukara::Command::Circle::Create
   Hirukara::Command::Circle::Search
   Hirukara::Command::Circle::Single
   Hirukara::Command::Circle::Update
   Hirukara::Command::Member::Create
   Hirukara::Command::Member::Select
   Hirukara::Command::Notice::Select
   Hirukara::Command::Notice::Update
   Hirukara::Command::Statistic::Select
/], "command class listing ok";
