use utf8;
use strict;
use t::Util;
use Test::More tests => 1;
use Test::Exception;
use Hash::MultiValue;

my $m = create_mock_object;
my $h = Hash::MultiValue->new;

ok 1;
__END__
subtest "die on invalid filetype" => sub {
    plan tests => 2;
    exception_ok { 
        $m->run_command('checklist.export' => {
            type         => 'moge',
            where        => $h,
            template_var => {},
            member_id    => 'fugafuga',
        });
    } 'Hirukara::Checklist::InvalidExportTypeException', qr/unknown type 'moge'/;
};

subtest "export ok" => sub {
    plan tests => 20;
    my @conf = (
        { type => 'checklist',      ext => 'csv' },
        { type => 'pdf_order',      ext => 'pdf' },
        { type => 'pdf_buy',        ext => 'pdf' },
        { type => 'pdf_distribute', ext => 'pdf' },
    );

    for my $c (@conf)   {
        my $type = $c->{type};
        my $ext  = $c->{ext};
        my $ret  = $m->run_command('checklist.export' => {
            type         => $type,
            where        => $h,
            template_var => {},
            member_id    => 'fugafuga',
        });

        ok my $file = delete $ret->{file}, "key 'file' ok";
        isa_ok $file, 'File::Temp';
        is_deeply $ret, { exhibition => 'ComicMarket999', extension => $ext }, "return value ok";

        test_actionlog_ok $m, {
            id         => 1,
            circle_id  => undef,
            member_id  => 'fugafuga',
            message_id => qq!チェックリストをエクスポートします。 (type=$type, member_id=fugafuga, cond=bless( {'unordered' => 0}, 'Hash::MultiValue' ))!,
            parameters => qq!["チェックリストをエクスポートします。","type","$type","member_id","fugafuga","cond","bless( {'unordered' => 0}, 'Hash::MultiValue' )"]!,
        };
    }
};

subtest "checklist csv not exported on exhibition is undef" => sub {
    plan tests => 2;
    exception_ok {
        local $m->{exhibition} = '';
        $m->run_command('checklist.export' => {
            type         => 'checklist',
            where        => $h,
            template_var => {},
            member_id    => 'fugafuga',
        })
    } 'Hirukara::Checklist::NotAComiketException'
     , qr/現在受け付けている '' はコミケットではないのでこの操作は実行出来ません。/
     , 'die on exhibition is undef';
};

subtest "checklist csv not exported on exhibition is mogemoge" => sub {
    plan tests => 2;
    exception_ok {
        $m->run_command('checklist.export' => {
            type         => 'checklist',
            where        => $h,
            template_var => {},
            member_id    => 'fugafuga',
        })
    } 'Hirukara::Checklist::NotAComiketException'
     , qr/現在受け付けている 'mogemoge' はコミケットではないのでこの操作は実行出来ません/
     , 'die on exhibition is not a comiket';
};

subtest "checklist csv not exported on exhibition is comiket" => sub {
    plan tests => 3;

    my $ret = $m->run_command('checklist.export' => {
        type         => 'checklist',
        where        => $h,
        template_var => {},
        member_id    => 'fugafuga',
    });

    my $text = do { open my $fh, $ret->{file} or die; local $/; <$fh> };
    is $text, 'Header,ComicMarketCD-ROMCatalog,ComicMarket99,UTF-8,Windows 1.86.1', 'csv content ok';

    test_actionlog_ok $m, {
        id      => 1,
        circle_id  => undef,
        member_id  => 'fugafuga',
        message_id => q!チェックリストをエクスポートします。 (type=checklist, member_id=fugafuga, cond=bless( {'unordered' => 0}, 'Hash::MultiValue' ))!,
        parameters => qq!["チェックリストをエクスポートします。","type","checklist","member_id","fugafuga","cond","bless( {'unordered' => 0}, 'Hash::MultiValue' )"]!
    };
};

subtest "checklist csv not exported on exhibition is comiket 3 digit" => sub {
    plan tests => 3;

    my $ret = $m->run_command('checklist.export' => {
        type         => 'checklist',
        where        => $h,
        template_var => {},
        member_id    => 'fugafuga',
    });

    my $text = do { open my $fh, $ret->{file} or die; local $/; <$fh> };
    is $text, 'Header,ComicMarketCD-ROMCatalog,ComicMarket100,UTF-8,Windows 1.86.1', 'csv content ok';

    test_actionlog_ok $m, {
        id      => 1,
        circle_id  => undef,
        member_id  => 'fugafuga',
        message_id => q!チェックリストをエクスポートします。 (type=checklist, member_id=fugafuga, cond=bless( {'unordered' => 0}, 'Hash::MultiValue' ))!,
        parameters => qq!["チェックリストをエクスポートします。","type","checklist","member_id","fugafuga","cond","bless( {'unordered' => 0}, 'Hash::MultiValue' )"]!
    };
};
