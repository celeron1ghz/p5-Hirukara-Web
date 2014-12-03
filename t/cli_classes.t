use strict;
use Test::More tests => 1;
use Hirukara::CLI;

is_deeply [ Hirukara::CLI->get_all_command_object ],[ qw/
   Hirukara::Command::Actionlog::Select
   Hirukara::Command::Auth::Create
   Hirukara::Command::Auth::Select
   Hirukara::Command::Checklist::Merge
   Hirukara::Command::Member::Create
   Hirukara::Command::Notice::Select
   Hirukara::Command::Notice::Update
   Hirukara::Command::Statistic::Select
/], "command class listing ok";
