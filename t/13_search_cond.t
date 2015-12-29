use utf8;
use t::Util;
use Test::More tests => 9;
use Hirukara::SearchCondition;

my $m = create_mock_object;
my $cond = Hirukara::SearchCondition->new(database => $m->db);

sub test_cond_ok    {
    my($param,$str,$sql,$bind) = @_;
    my $ret  = $cond->run($param);
    my $cond = $ret->{condition};

    is $ret->{condition_label}, $str,  "condition string ok";
    is $cond->as_sql,           $sql,  "sql string is ok";
    is_deeply [$cond->bind],    $bind, "bind value is ok";
}

sub test_empty    {
    my($param,$str) = @_;
    $str||='なし';
    my $ret  = $cond->run($param);
    my $cond = $ret->{condition};
    is $ret->{condition_label}, $str, "condition string ok";
    is $cond, 0, "sql string is ok";
}

{
    $m->run_command('circle_type.create' => { type_name => 'ご配慮', scheme => 'info', run_by => 'moge'}); 
    $m->run_command('circle_type.create' => { type_name => '身内1',  scheme => 'info', run_by => 'moge'}); 
    $m->run_command('circle_type.create' => { type_name => '身内2',  scheme => 'info', run_by => 'moge'}); 
    $m->run_command('circle_type.create' => { type_name => '要確認', scheme => 'info', run_by => 'moge'}); 
    delete_cached_log $m;
}

subtest "empty test" => sub {
    plan tests => 2;
    test_empty {};
};

subtest "day test" => sub {
    plan tests => 7;
    test_empty   { day => undef };
    test_empty   { day => 0 };
    test_cond_ok { day => 3 }, "3日目" , "(`day` = ?)", [3];
};

#test_cond_ok { area => "東123" }
#    , "エリア=東123"
#    , "(`circle`.`circle_sym` IN (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?))"
#    , [qw/Ａ Ｂ Ｃ Ｄ Ｅ Ｆ Ｇ Ｈ Ｉ Ｊ Ｋ Ｌ Ｍ Ｎ Ｏ Ｐ Ｑ Ｒ Ｓ Ｔ Ｕ Ｖ Ｗ Ｘ Ｙ Ｚ ア イ ウ エ オ カ キ ク ケ コ サ/];

subtest "circle_type test" => sub {
    plan tests => 7;
    test_empty   { circle_type => undef };
    test_empty   { circle_type => 0 };
    test_cond_ok { circle_type => 1 }, "サークル属性=ご配慮", "(`circle_type` = ?)", [1];
};

subtest "member_id test" => sub {
    plan tests => 7;
    test_empty   { member_id => undef };
    test_empty   { member_id => 0 };
    test_cond_ok { member_id => "mogemoge" }
        , q/メンバー="mogemoge"/
        , '(`circle`.`id` IN (SELECT circle_id FROM circle_book JOIN circle_order ON circle_book.id = circle_order.book_id WHERE circle_order.member_id = ?))',
        , ["mogemoge"];
};

subtest "assign test" => sub {
    plan tests => 7;
    test_empty   { assign => undef };
    test_empty   { assign => 0 };
    test_cond_ok { assign => 11 }
        , q/割当="ID:11"/
        , "(`circle`.`id` IN (SELECT circle_id FROM assign WHERE assign_list_id = ?))"
        , [11];
};

subtest "assign test" => sub {
    test_empty   { unordered => undef };
    test_empty   { unordered => 1 }, '誰も発注していないサークルを含む';
    test_cond_ok { unordered => 0 }
        , 'なし'
        , '(`circle`.`id` IN (SELECT circle_book.circle_id FROM circle_book LEFT JOIN circle_order ON circle_book.id = circle_order.book_id WHERE circle_order.id IS NOT NULL))',
        , [];
};

subtest "complex test" => sub {
    plan tests => 6;
    test_cond_ok { day => 2, area => "西12", circle_type => 4, member_id => "fugafuga", assign => 100 }
        , q/2日目, サークル属性=要確認, メンバー="fugafuga", 割当="ID:100"/
        , "(`day` = ?)"
        . " AND (`circle_type` = ?)"
        . " AND (`circle`.`id` IN (SELECT circle_id FROM circle_book JOIN circle_order ON circle_book.id = circle_order.book_id WHERE circle_order.member_id = ?))"
        . " AND (`circle`.`id` IN (SELECT circle_id FROM assign WHERE assign_list_id = ?))"
        , [qw/2 4 fugafuga 100/];

    #test_cond_ok { day => 2, area => "西12", circle_type => 4, member_id => "fugafuga", assign => 100 }
    #    , q/2日目, エリア=西12, サークル属性=要確認, メンバー="fugafuga", 割当="ID:100"/
    #    , "(`day` = ?)"
    #      . " AND (`circle`.`circle_sym` IN (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?))"
    #      . " AND (`circle_type` = ?)"
    #      . " AND (`circle`.`id` IN (SELECT circle_id FROM checklist WHERE member_id = ?))"
    #      . " AND (`circle`.`id` IN (SELECT circle_id FROM assign WHERE assign_list_id = ?))"
    #    , [qw/2 に ぬ ね の は ひ ふ へ ほ ま み む め も や ゆ よ ら り る れ あ い う え お か き く け こ さ し す せ そ た ち つ て と な 4 fugafuga 100/];

    test_cond_ok { day => 2, circle_type => 4, assign => 100 }
        , q/2日目, サークル属性=要確認, 割当="ID:100"/
        , "(`day` = ?) AND (`circle_type` = ?) AND (`circle`.`id` IN (SELECT circle_id FROM assign WHERE assign_list_id = ?))"
        , [2, 4, 100];
};

{
    $m->run_command('member.create' => {
        id          => '12345',
        member_id   => 'moge',
        member_name => 'もげさん',
        image_url   => 'url',
    });

    $m->run_command('assign_list.create' => { run_by => "mogemoge", exhibition => 'moge' }) for 1 .. 2;

    ## assign exist and member exist
    $m->run_command('assign_list.update' => {
        assign_id        => 1,
        assign_member_id => 'moge',
        assign_name      => 'もげリスト',
        run_by           => 'mogemoge',
    });

    ## assign exist and member not exist
    $m->run_command('assign_list.update' => {
        assign_id        => 2,
        assign_member_id => 'fuga',
        assign_name      => 'ふがリスト',
        run_by           => 'mogemoge',
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
