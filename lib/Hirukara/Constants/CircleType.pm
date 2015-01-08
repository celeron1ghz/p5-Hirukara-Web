package Hirukara::Constants::CircleType;
use utf8;
use strict;
use warnings;

my %LOOKUP = (
    1  => { class => "gohairyo",    value => 1,  label => 'ご配慮' },
    2  => { class => "families",    value => 2,  label => '身内' },
    3  => { class => "absent",      value => 3,  label => '欠席' },
    4  => { class => "confirm",     value => 4,  label => '要確認' },
    5  => { class => "malonu",      value => 5,  label => 'ﾇﾇﾝﾇ' },
    6  => { class => "noshinkan",   value => 6,  label => '新刊なし' },
    50 => { class => "fixed",       value => 50, label => 'fix α' },
    51 => { class => "fixed",       value => 51, label => 'fix β' },
    52 => { class => "fixed",       value => 52, label => 'fix γ' },
    53 => { class => "fixed",       value => 53, label => 'fix ω' },
    99 => { class => "deprecated",  value => 99, label => 'エラーデータ' },
);

sub lookup  {
    my $val = shift or return;
    $LOOKUP{$val};
}

sub circle_types    {
    values %LOOKUP;
}

1;
