package Hirukara::ComiketCsv;
use Mouse;
use JSON;

has checklists => ( is => 'rw', isa => 'ArrayRef' );

sub process {
    my $c = shift;
    my $checklists = $c->checklists;
    my @ret = ("Header,ComicMarketCD-ROMCatalog,ComicMarket86,UTF-8,Windows 1.86.1");

    for my $chk (@$checklists) {
        my $raw = decode_json $chk->{circle}->serialized;
        push @ret, "Circle,$raw->{serial_no}";
    }

    my $ret = join "\n", @ret;
    $ret;
}

1;
