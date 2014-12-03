use strict;
use Test::More tests => 14;
use_ok "Hirukara::CLI";

sub command {
    my($got,$expected) = @_;
    is Hirukara::CLI::to_command_name($got), $expected, "$got -> $expected";
}

sub clazz {
    my($got,$expected) = @_;
    is Hirukara::CLI::to_class_name($got), $expected, "$got -> $expected";
}


## to_command test
ok !Hirukara::CLI::to_command_name(),                 "undef return on no args";
ok !Hirukara::CLI::to_command_name(""),               "undef return on empty string";
ok !Hirukara::CLI::to_command_name("Moge"),           "undef return on not class name";
ok !Hirukara::CLI::to_command_name("Moge::Fuga"),     "undef return on not class name";
ok !Hirukara::CLI::to_command_name("Hirukara::Moge"), "undef return on not Hirukara::Command";

command "Hirukara::Command::Moge", "moge";
command "Hirukara::Command::Moge::Fuga", "moge_fuga";
command "Hirukara::Command::Moge::Fuga::Piyo", "moge_fuga_piyo";


## to_class test
ok !Hirukara::CLI::to_class_name(),                   "undef return on no args";
ok !Hirukara::CLI::to_class_name(""),                   "undef return on no args";

clazz "moge",           "Hirukara::Command::Moge";
clazz "moge_fuga",      "Hirukara::Command::Moge::Fuga";
clazz "moge_fuga_piyo", "Hirukara::Command::Moge::Fuga::Piyo";
