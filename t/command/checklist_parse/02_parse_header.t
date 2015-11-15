use strict;
use Test::More tests => 16;
use Test::Exception;
use t::Util;

exception_ok { test_reading_csv("") } "Hirukara::CSV::FileIsEmptyException", qr/file is empty/;

exception_ok { test_reading_csv(<<EOT) } "Hirukara::CSV::HeaderNumberIsWrongException", qr/column number is wrong/;

EOT

exception_ok { test_reading_csv(<<EOT) } "Hirukara::CSV::HeaderNumberIsWrongException", qr/column number is wrong/;
a,a,a,a
EOT

exception_ok { test_reading_csv(<<EOT) } "Hirukara::CSV::HeaderNumberIsWrongException", qr/column number is wrong/;
a,a,a,a,a,a
EOT

exception_ok { test_reading_csv(<<EOT) } "Hirukara::CSV::InvalidHeaderException", qr/header identifier is not valid/;
a,a,a,a,a
EOT

exception_ok { test_reading_csv(<<EOT) } "Hirukara::CSV::UnknownCharacterEncodingException", qr/unknown character encoding 'mogemoge'/;
Header,a,b,mogemoge,d
EOT

my $r1 = test_reading_csv(<<EOT);
Header,a,comiketno,utf8,source
EOT

is $r1->comiket_no, "comiketno", "comiketno ok";
is $r1->source, "source", "source ok";
isa_ok $r1->encoding, "Encode::utf8";
is scalar @{$r1->circles}, 0, "circle count ok";
