package Hirukara::Parser::CSV;
use Hirukara::Parser::CSV::Row;
use Mouse;
use Text::CSV;
use Encode;

has comiket_no => ( is => 'ro', isa => 'Str', required => 1 );
has source     => ( is => 'ro', isa => 'Str', required => 1 );
has circles    => ( is => 'ro', isa => 'ArrayRef', default => sub { [] });
has encoding   => ( is => 'ro', isa => 'Object', required => 1 );

sub read_from_file {
    my($class,$filename) = @_;
    my $parser = Text::CSV->new({ binary => 1 });

    open my $fh, $filename or die "$filename: $!";

    my $row = $parser->getline($fh) or die "$filename: file is empty";

    die "Invalid header: column number is wrong" if @$row != 5;

    die "Invalid header: header identifier is not valid" if $row->[0] ne "Header";

    die "Invalid header: unknown character encoding '$row->[3]'" unless my $encoding = find_encoding($row->[3]);
    binmode $fh, sprintf ":encoding(%s)", $encoding->name;

    my $csv = $class->new({ comiket_no => $row->[2], source => $row->[4], encoding => $encoding });
    my @columns = Hirukara::Parser::CSV::Row->sequence;

    while ( my $row = $parser->getline($fh) )  {
        next unless $row->[0] eq "Circle";

        my %hash;

        for (my $i = 0; $i < @columns; $i++)    {
            $hash{$columns[$i]} = $row->[$i];
        }

        my $o = Hirukara::Parser::CSV::Row->new(\%hash);
        push @{$csv->circles}, $o;
    }

    return $csv;
}

1;
