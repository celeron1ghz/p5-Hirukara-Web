use utf8;
use strict;
use t::Util;
use Time::Piece;
use Test::More tests => 6;

my $m = create_mock_object;
my $now = time;
my $dt1;
my $dt2;
my $dt3;
my $dt4;

subtest "create notice without id ok" => sub {
    plan tests => 4;
    my $ret;

    output_ok { $ret = $m->run_command('notice.update' => { member_id => 'mogemoge', title => "title 1", text => 'fugafuga' }) }
        qr/\[INFO\] 告知を作成しました。 \(id=1, key=$now, member_id=mogemoge, title=title 1, text_length=8\)/;

    is_deeply $ret->get_columns, {
        id         => 1,
        key        => $now,
        member_id  => "mogemoge",
        title      => "title 1",
        text       => "fugafuga",
        created_at => ($dt1 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
    }, "data structure ok";

    actionlog_ok $m ,{ message_id => "告知を作成しました。", circle_id => undef };
    delete_actionlog_ok $m, 1;
};

subtest "create notice with id ok" => sub {
    plan tests => 4;
    my $ret;

    output_ok {
        sleep 1;
        $ret = $m->run_command('notice.update' => { key => "9999999999", member_id => 'moge', title => "title 2", text => 'fuga' });
    } qr/\[INFO\] 告知を更新しました。 \(id=2, key=9999999999, member_id=moge, title=title 2, text_length=4\)/;

    is_deeply $ret->get_columns, {
        id         => 2,
        key        => "9999999999",
        member_id  => "moge",
        title      => "title 2",
        text       => "fuga",
        created_at => ($dt2 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
    }, "data structure ok";

    actionlog_ok $m ,{ message_id => "告知を更新しました。", circle_id => undef };
    delete_actionlog_ok $m, 1;
};

subtest "notice select ok" => sub {
    plan tests => 2;
    my $ret = $m->run_command('notice.select');

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "2",
            key        => "9999999999",
            title      => "title 2",
            text       => "fuga",
            member_id  => "moge",
            created_at => $dt2,
        },{
            id         => "1",
            key        => $now,
            title      => "title 1",
            text       => "fugafuga",
            member_id  => "mogemoge",
            created_at => $dt1,
        }
    ], "data structure is ok";

    delete_actionlog_ok $m, 0;
};

subtest "add new notice and that is selected" => sub {
    plan tests => 3;
    supress_log {
        sleep 1;
        $m->run_command('notice.update' => { key => "9999999999", member_id => 'mogumogu', title => "title 333", text => 'nemui' });
    };

    my $ret = $m->run_command('notice.select');

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "3",
            key        => "9999999999",
            title      => "title 333",
            text       => "nemui",
            member_id  => "mogumogu",
            created_at => ($dt3 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
        },{
            id         => "1",
            key        => $now,
            title      => "title 1",
            text       => "fugafuga",
            member_id  => "mogemoge",
            created_at => $dt1,
        }
    ], "data structure is ok";

    actionlog_ok $m ,{ message_id => "告知を更新しました。", circle_id => undef };
    delete_actionlog_ok $m, 1;
};

subtest "add new notice and that is selected" => sub {
    plan tests => 3;
    supress_log {
        sleep 1;
        $m->run_command('notice.update' => { key => "$now", member_id => 'berobero', title => "title 4444", text => 'zuzuzu' });
    };

    my $ret = $m->run_command('notice.select');

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "3",
            key        => "9999999999",
            title      => "title 333",
            text       => "nemui",
            member_id  => "mogumogu",
            created_at => $dt3,
        },{
            id         => "4",
            key        => $now,
            title      => "title 4444",
            text       => "zuzuzu",
            member_id  => "berobero",
            created_at => ($dt4 = localtime->strftime("%Y-%m-%d %H:%M:%S")),
        }
    ], "data structure is ok";

    actionlog_ok $m ,{ message_id => "告知を更新しました。", circle_id => undef };
    delete_actionlog_ok $m, 1;
};

subtest "notice_single works" => sub {
    plan tests => 1;
    my $ret = $m->run_command('notice.single' => { key => $now });

    is_deeply [ map { $_->get_columns } @$ret ], [
        {
            id         => "4",
            key        => $now,
            title      => "title 4444",
            text       => "zuzuzu",
            member_id  => "berobero",
            created_at => $dt4,
        },{
            id         => "1",
            key        => $now,
            title      => "title 1",
            text       => "fugafuga",
            member_id  => "mogemoge",
            created_at => $dt1,
        }
    ], "data structure is ok";
};
