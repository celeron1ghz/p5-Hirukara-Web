use strict;
use Test::More tests => 13;
use Hirukara;

sub command {
    my($got,$expected) = @_;
    is +Hirukara->to_command_name($got), $expected, "$got -> $expected";
}

sub clazz {
    my($got,$expected) = @_;
    is +Hirukara->to_class_name($got), $expected, "$got -> $expected";
}

## to_command test
ok !Hirukara->to_command_name(),                 "undef return on no args";
ok !Hirukara->to_command_name(""),               "undef return on empty string";
ok !Hirukara->to_command_name("Moge"),           "undef return on not class name";
ok !Hirukara->to_command_name("Moge::Fuga"),     "undef return on not class name";
ok !Hirukara->to_command_name("Hirukara::Moge"), "undef return on not Hirukara::Command";

command "Hirukara::Command::Moge", "moge";
command "Hirukara::Command::Moge::Fuga", "moge_fuga";
command "Hirukara::Command::Moge::Fuga::Piyo", "moge_fuga_piyo";

## to_class test
ok !Hirukara->to_class_name(),                   "undef return on no args";
ok !Hirukara->to_class_name(""),                 "undef return on no args";

clazz "moge",           "Hirukara::Command::Moge";
clazz "moge_fuga",      "Hirukara::Command::Moge::Fuga";
clazz "moge_fuga_piyo", "Hirukara::Command::Moge::Fuga::Piyo";
