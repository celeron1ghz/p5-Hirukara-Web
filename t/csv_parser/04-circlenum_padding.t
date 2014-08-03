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

my $r1 = test_reading_csv(<<EOT);
Header,a,comiketno,utf8,source
Circle,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
Circle,2,3,4,5,6,7,8,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
EOT

is scalar @{$r1->circles}, 2, "circle count ok";

my $c1 = $r1->circles->[0];
my $c2 = $r1->circles->[1];
is $c1->circle_num, "09", "zero padding circle num";
is $c2->circle_num, "09", "zero padding circle num";
