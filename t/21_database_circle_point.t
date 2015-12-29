use utf8;
use strict;
use t::Util;
use Test::More tests => 4;
use Encode;
use Hirukara::Area;

my $m = create_mock_object;
my $area = Hirukara::Area->new;
my $cnt;

my $gohairyo = $m->run_command('circle_type.create' => { type_name => 'ご配慮', scheme => 'moge', run_by => 'fuga' });
my $miuti    = $m->run_command('circle_type.create' => { type_name => '身内',   scheme => 'moge', run_by => 'fuga' });
my $nunnu    = $m->run_command('circle_type.create' => { type_name => 'ﾇﾇﾝﾇ',   scheme => 'moge', run_by => 'fuga' });

sub test_point  {
    my($opt,$a,$point) = @_;
    my $c = create_mock_circle $m, circle_name => "circle " . ++$cnt, %$opt;
    is $area->get_area($c), $a, "area is $a";
    is $c->circle_point, $point, "default is $point";

    my $c1 = $m->db->single(circle => {id => $c->id});
    $m->db->update($c1, { circle_point => 0 });
    is $m->db->single(circle => {id => $c->id})->circle_point, 0, 'updated to 0';

    is $c1->recalc_circle_point, $point, "point is $point";
    is $m->db->single(circle => {id => $c->id})->circle_point, $point, "point affected to database";
    $c;
}

subtest "circle_point() with normal" => sub {
    plan tests => 5 * 4;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 3,     circle_type => 0 }, "東1壁", 10;
    test_point { day => 1, circle_sym => "Ｂ",  circle_num => 4,     circle_type => 0 }, "東1偽壁", 5;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 4,     circle_type => 0 }, "東1シャッター", 20;
    test_point { day => 1, circle_sym => "Ｃ",  circle_num => 1,     circle_type => 0 }, "東1誕生日席", 2;
};

subtest "circle_point() with gohairyo" => sub {
    plan tests => 5 * 4;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 3,     circle_type => $gohairyo->id }, "東1壁", 1;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 4,     circle_type => $gohairyo->id }, "東1シャッター", 1;
    test_point { day => 1, circle_sym => "Ｂ",  circle_num => 4,     circle_type => $gohairyo->id }, "東1偽壁", 1;
    test_point { day => 1, circle_sym => "Ｃ",  circle_num => 1,     circle_type => $gohairyo->id }, "東1誕生日席", 1;
};

subtest "circle_point() with gohairyo" => sub {
    plan tests => 5 * 4;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 3,     circle_type => $miuti->id }, "東1壁", 1;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 4,     circle_type => $miuti->id }, "東1シャッター", 1;
    test_point { day => 1, circle_sym => "Ｂ",  circle_num => 4,     circle_type => $miuti->id }, "東1偽壁", 1;
    test_point { day => 1, circle_sym => "Ｃ",  circle_num => 1,     circle_type => $miuti->id }, "東1誕生日席", 1;
};

subtest "circle_point() with nunnu" => sub {
    ## with nunnu! ( ◜◡◝ )
    plan tests => 5 * 4;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 3,     circle_type => $nunnu->id }, "東1壁", 20;
    test_point { day => 1, circle_sym => "Ａ",  circle_num => 4,     circle_type => $nunnu->id }, "東1シャッター", 30;
    test_point { day => 1, circle_sym => "Ｂ",  circle_num => 4,     circle_type => $nunnu->id }, "東1偽壁", 15;
    test_point { day => 1, circle_sym => "Ｃ",  circle_num => 1,     circle_type => $nunnu->id }, "東1誕生日席", 12;
};
