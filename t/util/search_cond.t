use utf8;
use t::Util;
use Test::More tests => 24;
use Hirukara::SearchCondition;

my $m = create_mock_object;
my $cond = Hirukara::SearchCondition->new(database => $m->database);

sub test_search_cond    {
    my($param,$str,$sql,$bind) = @_;
    my $ret  = $cond->run($param);
    my $cond = $ret->{condition};

    is $ret->{condition_label}, $str,  "condition string ok";
    is $cond->as_sql,           $sql,  "sql string is ok";
    is_deeply [$cond->bind],    $bind, "bind value is ok";
}

supress_log {
    $m->run_command(circletype_create => { type_name => 'ご配慮', scheme => 'info' }); 
    $m->run_command(circletype_create => { type_name => '身内1', scheme => 'info' }); 
    $m->run_command(circletype_create => { type_name => '身内2', scheme => 'info' }); 
    $m->run_command(circletype_create => { type_name => '要確認', scheme => 'info' }); 
};

is_deeply +Hirukara::SearchCondition->run({}), { condition => 0, condition_label => 'なし' };

test_search_cond { day => 3 }
    , "3日目"
    , "(`day` = ?)"
    , [3];

test_search_cond { area => "東123" }
    , "エリア=東123"
    , "(`circle`.`circle_sym` IN (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?))"
    , [qw/Ａ Ｂ Ｃ Ｄ Ｅ Ｆ Ｇ Ｈ Ｉ Ｊ Ｋ Ｌ Ｍ Ｎ Ｏ Ｐ Ｑ Ｒ Ｓ Ｔ Ｕ Ｖ Ｗ Ｘ Ｙ Ｚ ア イ ウ エ オ カ キ ク ケ コ サ/];

test_search_cond { circle_type => 1 }
    , "サークル属性=ご配慮"
    , "(`circle_type` = ?)"
    , [1];

test_search_cond { member_id => "mogemoge" }
    , q/メンバー="mogemoge"/
    , "(`circle`.`id` IN (SELECT circle_id FROM checklist WHERE member_id = ?))"
    , ["mogemoge"];

test_search_cond { assign => 11 }
    , q/割当="ID:11"/
    , "(`circle`.`id` IN (SELECT circle_id FROM assign WHERE assign_list_id = ?))"
    , [11];

test_search_cond { day => 2, area => "西12", circle_type => 4, member_id => "fugafuga", assign => 100 }
    , q/2日目, エリア=西12, サークル属性=要確認, メンバー="fugafuga", 割当="ID:100"/
    , "(`day` = ?)"
      . " AND (`circle`.`circle_sym` IN (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?))"
      . " AND (`circle_type` = ?)"
      . " AND (`circle`.`id` IN (SELECT circle_id FROM checklist WHERE member_id = ?))"
      . " AND (`circle`.`id` IN (SELECT circle_id FROM assign WHERE assign_list_id = ?))"
    , [qw/2 に ぬ ね の は ひ ふ へ ほ ま み む め も や ゆ よ ら り る れ あ い う え お か き く け こ さ し す せ そ た ち つ て と な 4 fugafuga 100/];

test_search_cond { day => 2, circle_type => 4, assign => 100 }
    , q/2日目, サークル属性=要確認, 割当="ID:100"/
    , "(`day` = ?) AND (`circle_type` = ?) AND (`circle`.`id` IN (SELECT circle_id FROM assign WHERE assign_list_id = ?))"
    , [2, 4, 100];

supress_log {
    $m->run_command(member_create => {
        id          => '12345',
        member_id   => 'moge',
        member_name => 'もげさん',
        image_url   => 'url',
    });

    $m->run_command(assignlist_create => { member_id => "mogemoge", exhibition => 'moge' }) for 1 .. 2;

    ## assign exist and member exist
    $m->run_command(assignlist_update => {
        assign_id        => 1,
        member_id        => 'mogemoge',
        assign_member_id => 'moge',
        assign_name      => 'もげリスト',
    });

    ## assign exist and member not exist
    $m->run_command(assignlist_update => {
        assign_id        => 2,
        member_id        => 'mogemoge',
        assign_member_id => 'fuga',
        assign_name      => 'ふがリスト',
    });
};

subtest "assign label" => sub {
    plan tests => 3;
    is $cond->run({ assign => 1 })->{condition_label}, q/割当="ID:1 もげリスト[もげさん]"/, "member label and assign label ok";
    is $cond->run({ assign => 2 })->{condition_label}, q/割当="ID:2 ふがリスト[fuga]"/,     "not member label and assign label ok";
    is $cond->run({ assign => 3 })->{condition_label}, q/割当="ID:3"/,                      "not member label and not assign label ok";
};

subtest "member label" => sub {
    plan tests => 2;
    is $cond->run({ member_id => "moge" })->{condition_label}, q/メンバー="もげさん(moge)"/,  "member exists";
    is $cond->run({ member_id => "fuga" })->{condition_label}, q/メンバー="fuga"/,            "member not exists";
};
