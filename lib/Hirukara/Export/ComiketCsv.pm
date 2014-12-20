package Hirukara::Export::ComiketCsv;
use utf8;
use Mouse;
use JSON;
use Hirukara::Parser::CSV;
use Encode;

with 'Hirukara::Export';

sub get_extension { "csv" }

sub process {
    my $c = shift;
    my $checklists = $c->checklists;
    my @ret = (
        sprintf("Header,ComicMarketCD-ROMCatalog,ComicMarket86,UTF-8,Windows 1.86.1"),
    );

    for my $circle (@$checklists) {
        my $raw = decode_json $circle->serialized;
        my $row = Hirukara::Parser::CSV::Row->new($raw);
        my $fav = $circle->checklists;
        my @comment;
        my $cnt = 0;

        for my $f (@$fav)   {
            $cnt += ($f->{count} || 0);

            if ($f->{comment})    {
                push @comment, sprintf "%s=[%s]", $f->member_id, $f->comment;
            }
        }

        my $remark = $circle->comment ? sprintf("[%s] ", $circle->comment) : "";
        my $comment = sprintf "%s%d冊 / %s", $remark, $cnt, join(", " => @comment);
        $comment =~ s/[\r\n]/  /g;

        $row->color(1);
        $row->comment(qq/"$comment"/);
        $row->remark(sprintf q/"%s"/, $row->remark);
        push @ret, encode_utf8 $row->as_csv_column;
    }

    print {$c->file} join "\n", @ret;
}

1;
