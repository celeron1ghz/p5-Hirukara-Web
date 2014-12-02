package Hirukara::Parser::CSV;
use Mouse;
use Text::CSV;
use Encode;

has comiket_no => ( is => 'ro', isa => 'Str', required => 1 );
has source     => ( is => 'ro', isa => 'Str', required => 1 );
has circles    => ( is => 'ro', isa => 'ArrayRef', default => sub { [] });
has encoding   => ( is => 'ro', isa => 'Object', required => 1 );

my %FILE_FILTER = (
    circle_num  => sub {
        my $val = shift;
        sprintf "%02s", $val;
    },
);

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
            my $column = $columns[$i];
            my $filter = $FILE_FILTER{$column};
            my $value  = $row->[$i];
            $hash{$column} = $filter ? $filter->($value) : $value;
        }

        my $o = Hirukara::Parser::CSV::Row->new(\%hash);
        push @{$csv->circles}, $o;
    }

    return $csv;
}


package Hirukara::Parser::CSV::Row;
use Mouse;

sub required_columns    {
    (
        'day',          # 06
        'circle_sym',   # 08
        'circle_num',   # 09
        'circle_flag',  # 22
        'circle_name',  # 11
        'circle_author',# 13
    )
}

sub optional_columns {
    (
        'type',         # 01
        'serial_no',    # 02
        'color',        # 03
        'page_no',      # 04
        'cut_index',    # 05
        'area',         # 07
        'genre',        # 10
        'circle_kana',  # 12
        'publish_info', # 14
        'url',          # 15
        'mail',         # 16
        'remark',       # 17
        'comment',      # 18
        'map_x',        # 19
        'map_y',        # 20
        'map_layout',   # 21
        'update_info',  # 23
        'circlems',     # 24
        'rss',          # 25
        'rss_info',     # 26
    );
}


sub sequence    {
    (
        'type',         # 01
        'serial_no',    # 02
        'color',        # 03
        'page_no',      # 04
        'cut_index',    # 05
        'day',          # 06
        'area',         # 07
        'circle_sym',   # 08
        'circle_num',   # 09
        'genre',        # 10
        'circle_name',  # 11
        'circle_kana',  # 12
        'circle_author',# 13
        'publish_info', # 14
        'url',          # 15
        'mail',         # 16
        'remark',       # 17
        'comment',      # 18
        'map_x',        # 19
        'map_y',        # 20
        'map_layout',   # 21
        'circle_flag',  # 22
        'update_info',  # 23
        'circlems',     # 24
        'rss',          # 25
        'rss_info',     # 26
    )
}
 
has $_ => ( is => 'rw', isa => 'Str', required => 1 ) for __PACKAGE__->required_columns;

has $_ => ( is => 'rw', isa => 'Str|Undef' ) for __PACKAGE__->optional_columns;

sub as_csv_column   {
    my $self = shift;
    join "," => map { $self->$_ } $self->sequence;
}

1;
