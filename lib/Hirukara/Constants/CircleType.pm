package Hirukara::Constants::CircleType;
use strict;
use utf8;

my %LOOKUP = (
    1 => { class => "gohairyo", value => 1, label => 'ご配慮' },
    2 => { class => "families", value => 2, label => '身内' },
    3 => { class => "absent",   value => 3, label => '欠席' },
    4 => { class => "confirm",  value => 4, label => '要確認' },
    5 => { class => "malonu",   value => 5, label => 'ﾇﾇﾝﾇ' },
);

sub lookup  {
    my($val) = @_;
    $LOOKUP{$val};
}

sub circle_types    {
    values %LOOKUP;
}

1;
