package Hirukara::Constants::CircleType;
use strict;
use utf8;

my %LOOKUP = (
    1 => { class => "gohairyo", value => 1, label => 'ご配慮' },
    2 => { class => "families", value => 2, label => '身内' },
    3 => { class => "absent",   value => 3, label => '不参加・新刊落ちた' },
);

sub lookup  {
    my($val) = @_;
    $LOOKUP{$val};
}

sub circle_types    {
    values %LOOKUP;
}

1;
