package Hirukara::Export::ComiketCsv;
use Mouse;
use JSON;
use Hirukara::Parser::CSV::Row;
use Encode;

has checklists => ( is => 'rw', isa => 'ArrayRef' );

sub get_extension { "csv" }

sub process {
    my $c = shift;
    my $checklists = $c->checklists;
    my @ret = ("Header,ComicMarketCD-ROMCatalog,ComicMarket86,UTF-8,Windows 1.86.1");

    for my $chk (@$checklists) {
        my $raw = decode_json $chk->{circle}->serialized;
        my $row = Hirukara::Parser::CSV::Row->new($raw);
        $row->color(1);
        $row->comment("");
        push @ret, encode_utf8 $row->as_csv_column;
    }

    my $ret = join "\n", @ret;
    $ret;
}

1;
