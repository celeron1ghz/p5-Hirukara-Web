use strict;
use Test::More tests => 3;
use Test::Exception;

use Hirukara::Parser::CSV;
use File::Temp 'tempfile';

sub make_temporary_file {
    my $val = shift;
    my($fh,$filename) = tempfile;
    print $fh $val;
    close $fh;
    return $filename;
}

sub test_reading_csv {
    my($content) = @_;
    my $file = make_temporary_file($content);
    Hirukara::Parser::CSV->read_from_file($file);
}


throws_ok { test_reading_csv("") } qr/file is empty/, "die on empty file";

throws_ok { test_reading_csv(<<EOT) } qr/column number is wrong/, "die on header format fail";

EOT

throws_ok { test_reading_csv(<<EOT) } qr/column number is wrong/, "die on header is not enough";
a,a,a,a
EOT

throws_ok { test_reading_csv(<<EOT) } qr/column number is wrong/, "die on header is too many";
a,a,a,a,a,a
EOT

throws_ok { test_reading_csv(<<EOT) } qr/header identifier is not valid/, "die on header identifier is not exist";
a,a,a,a,a
EOT

throws_ok { test_reading_csv(<<EOT) } qr/unknown character encoding 'mogemoge'/, "die on header charset is invalid";
Header,a,b,mogemoge,d
EOT

my $r1 = test_reading_csv(<<EOT);
Header,a,comiketno,utf8,source
EOT

is $r1->comiket_no, "comiketno", "comiketno ok";
is $r1->source, "source", "source ok";
isa_ok $r1->encoding, "Encode::utf8";
