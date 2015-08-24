use utf8;
use strict;
use t::Util;
use Test::More tests => 2;
use Test::Exception;
use Hash::MultiValue;

my $m = create_mock_object;
my $h = Hash::MultiValue->new;

subtest "die on invalid filetype" => sub {
    plan tests => 2;
    exception_ok { 
        $m->run_command('checklist.export' => {
            type         => 'moge',
            where        => $h,
            template_var => {},
            exhibition   => 'mogemoge',
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
        my $ret;
        my $type = $c->{type};
        my $ext  = $c->{ext};

        lives_ok {
            output_ok {
                $ret = $m->run_command('checklist.export' => {
                    type         => $type,
                    where        => $h,
                    template_var => {},
                    exhibition   => 'mogemoge',
                    member_id    => 'fugafuga',
                });
            } qr/\[INFO\] チェックリストをエクスポートします。 \(type=$type, member_id=fugafuga, cond=bless\( {}, 'Hash::MultiValue' \)\) at/;
        } "not die on export";

        ok my $file = delete $ret->{file}, "key 'file' ok";
        isa_ok $file, 'File::Temp';
        is_deeply $ret, { exhibition => 'mogemoge', extension => $ext }, "return value ok";
    }
};

