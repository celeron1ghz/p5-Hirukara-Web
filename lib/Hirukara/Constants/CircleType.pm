package Hirukara::Constants::CircleType;
use utf8;
use strict;
use warnings;

my %LOOKUP = (
    1  => { class => "info",    value => 1,  label => 'ご配慮' },
    2  => { class => "success", value => 2,  label => '身内' },
    3  => { class => "default", value => 3,  label => '欠席' },
    4  => { class => "warning", value => 4,  label => '要確認' },
    5  => { class => "danger",  value => 5,  label => 'ﾇﾇﾝﾇ' },
    6  => { class => "default", value => 6,  label => '新刊なし' },
    50 => { class => "info",    value => 50, label => 'fix α' },
    51 => { class => "info",    value => 51, label => 'fix β' },
    52 => { class => "info",    value => 52, label => 'fix γ' },
    53 => { class => "info",    value => 53, label => 'fix ω' },
    54 => { class => "info",    value => 54, label => 'ご配慮(7/26〆)' },
    55 => { class => "info",    value => 55, label => 'ご配慮(8/02〆)' },
    56 => { class => "info",    value => 56, label => 'ご配慮(7/31〆)' },
    99 => { class => "default", value => 99, label => 'エラーデータ' },
);

sub lookup  {
    my $val = shift or return;
    $LOOKUP{$val};
}

sub circle_types    {
    values %LOOKUP;
}

1;
