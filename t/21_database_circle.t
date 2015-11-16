use utf8;
use strict;
use t::Util;
use Test::More tests => 2;
use Encode;
use Hirukara::DB::Row::Circle;

subtest "DB::Circle->circle_space ok" => sub {
    sub space_ok    {
        my($args,$space) = @_;
        my $self = create_object_mock($args);
        local @Plack::Util::Prototype::ISA = 'Hirukara::DB::Row::Circle';
        is $self->circle_space, $space, encode_utf8 "circle space is '$space'";
    }

    space_ok { comiket_no => 'C99', day => 1, circle_sym => "Ｃ", circle_num => 1, circle_flag => "b" }, "C99 1日目 Ｃ01b";
};

subtest "DB::Circle->simple_circle_space ok" => sub {
    sub simple_space_ok    {
        my($args,$space) = @_;
        my $self = create_object_mock($args);
        local @Plack::Util::Prototype::ISA = 'Hirukara::DB::Row::Circle';
        is $self->simple_circle_space, $space, encode_utf8 "circle space is '$space'";
    }

    simple_space_ok { area => "東123", circle_sym => "Ｃ", circle_num => 1, circle_flag => "b" }, "東123 Ｃ01b";
};
