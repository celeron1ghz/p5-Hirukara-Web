use utf8;
use strict;
use t::Util;
use Test::More tests => 1;
use Hash::MultiValue;

sub hash { Hash::MultiValue->new(@_) }

my $m  = create_mock_object;
my $l1 = $m->run_command('assign_list.create', { day => 1, run_by => 'moge' });

subtest "error on exporting list is empty" => sub {
    plan tests => 8;
    exception_ok { $m->run_command('export.comiket_csv', { where => hash(), run_by => 'moge' }) }
        'Hirukara::Checklist::NoSuchCircleInListException',
        qr/^出力しようとしたリストにはサークルが存在しません。\(csv, cond=なし\)/;

    exception_ok { $m->run_command('export.order_pdf', { member_id => 'mogemoge', run_by => 'moge' }) }
        'Hirukara::Checklist::NoSuchCircleInListException',
        qr/^出力しようとしたリストにはサークルが存在しません。\(mid=mogemoge\)/;

    exception_ok { $m->run_command('export.distribute_pdf', { assign_list_id => $l1->id, run_by => 'moge' }) }
        'Hirukara::Checklist::NoSuchCircleInListException',
        qr/^出力しようとしたリストにはサークルが存在しません。\(aid=1\)/;

    exception_ok { $m->run_command('export.buy_pdf', { where => hash(), run_by => 'moge' }) }
        'Hirukara::Checklist::NoSuchCircleInListException',
        qr/^出力しようとしたリストにはサークルが存在しません。\(pdf, cond=なし\)/;
};
