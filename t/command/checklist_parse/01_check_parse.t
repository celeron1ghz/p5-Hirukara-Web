use strict;
use Test::More;
use Test::Exception;
use Hirukara::Parser::CSV;

my @tests = (
    { file => "web.csv", count => 66 },
    { file => "catarom.csv", count => 36 },
);

plan tests => @tests * 2;

for my $t (@tests)  {
    my $file = $t->{file};
    my $ret;
    lives_ok { $ret = Hirukara::Parser::CSV->read_from_file("t/checklist/$file") } "not die on parsing $file";
    is scalar @{$ret->circles}, $t->{count}, "parsing $file result ok";
}
