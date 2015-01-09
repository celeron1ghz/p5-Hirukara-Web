use utf8;
use strict;
use t::Util;
use Test::More tests => 3;
use Encode;
use Hirukara::Database::Row::Circle;

subtest "Database::Circle->circle_point ok" => sub {
    sub score_ok    {
        my($args,$score) = @_;
        my $self = create_object_mock($args);
        local @Plack::Util::Prototype::ISA = 'Hirukara::Database::Row::Circle';
        is $self->circle_point, $score, "circle point is $score";
    }

    score_ok { day => 1, circle_sym => undef, circle_num => undef, circle_type => undef }, 0;
    score_ok { day => 1, circle_sym => undef, circle_num => undef, circle_type => 1 },     1;
    score_ok { day => 1, circle_sym => undef, circle_num => undef, circle_type => 2 },     1;
    score_ok { day => 1, circle_sym => undef, circle_num => undef, circle_type => 3 },     0;

    score_ok { day => 1, circle_sym => undef, circle_num => undef, circle_type => 0 }, 0;
    score_ok { day => 1, circle_sym => "Ａ",  circle_num => undef, circle_type => 0 }, 0;
    score_ok { day => 1, circle_sym => "Ａ",  circle_num => 3,     circle_type => 0 }, 10;
    score_ok { day => 1, circle_sym => "Ａ",  circle_num => 4,     circle_type => 0 }, 20;
    score_ok { day => 1, circle_sym => "Ｂ",  circle_num => 4,     circle_type => 0 }, 5;
    score_ok { day => 1, circle_sym => "Ｃ",  circle_num => 1,     circle_type => 0 }, 2;

    score_ok { day => 1, circle_sym => "Ａ",  circle_num => 3,     circle_type => 5 }, 20;
    score_ok { day => 1, circle_sym => "Ａ",  circle_num => 4,     circle_type => 5 }, 30;
    score_ok { day => 1, circle_sym => "Ｂ",  circle_num => 4,     circle_type => 5 }, 15;
    score_ok { day => 1, circle_sym => "Ｃ",  circle_num => 1,     circle_type => 5 }, 12;
};

subtest "Database::Circle->circle_space ok" => sub {
    sub space_ok    {
        my($args,$space) = @_;
        my $self = create_object_mock($args);
        local @Plack::Util::Prototype::ISA = 'Hirukara::Database::Row::Circle';
        is $self->circle_space, $space, encode_utf8 "circle space is '$space'";
    }

    space_ok { comiket_no => 'C99', day => 1, circle_sym => "Ｃ", circle_num => 1, circle_flag => "b" }, "C99 1日目 Ｃ01b";
};

subtest "Database::Circle->simple_circle_space ok" => sub {
    sub simple_space_ok    {
        my($args,$space) = @_;
        my $self = create_object_mock($args);
        local @Plack::Util::Prototype::ISA = 'Hirukara::Database::Row::Circle';
        is $self->simple_circle_space, $space, encode_utf8 "circle space is '$space'";
    }

    simple_space_ok { area => "東123", circle_sym => "Ｃ", circle_num => 1, circle_flag => "b" }, "東123 Ｃ01b";
};
