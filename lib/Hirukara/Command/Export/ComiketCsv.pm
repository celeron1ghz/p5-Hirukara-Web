package Hirukara::Command::Export::ComiketCsv;
use utf8;
use Moose;
use Encode;
use JSON;
use Hirukara::Exception;
use Hirukara::Parser::CSV;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exporter';

has where => ( is => 'ro', isa => 'Hash::MultiValue', required => 1 );

sub extension { 'csv' }

sub run {
    my $self = shift;
    my($list,$cond) = $self->get_all_prefetched($self->where);
    my $e = $self->hirukara->exhibition;
    $e =~ /^ComicMarket\d+$/ or Hirukara::Checklist::NotAComiketException->throw(exhibition => $e);

    my @circles = $list->all or Hirukara::Checklist::NoSuchCircleInListException->throw(list => "csv, cond=$cond->{condition_label}");
    my @ret = (
        sprintf("Header,ComicMarketCD-ROMCatalog,%s,UTF-8,Windows 1.86.1", $e),
    );

    for my $circle ($list->all) {
        my $raw = decode_json $circle->serialized;
        my $row = Hirukara::Parser::CSV::Row->new($raw);
        #my $fav = $circle->checklists or next;
        my @comment;
        my $cnt = 0;

        #for my $f (@$fav)   {
        #    $cnt += ($f->count || 0);

        #    if ($f->comment)    {
        #        push @comment, sprintf "%s=[%s]", $f->member->member_name, $f->comment;
        #    }
        #}

        #my $remark = $circle->comment ? sprintf("[%s] ", $circle->comment) : "";
        #my $comment = sprintf "%s%d冊 / %s", $remark, $cnt, join(", " => @comment);
        #$comment =~ s/[\r\n]/  /g;

        $row->color(1);
        #$row->comment(qq/"$comment"/);
        #$row->remark(sprintf q/"%s"/, $row->remark);
        push @ret, encode_utf8 $row->as_csv_column;
    }

    my $file = $self->file;
    print {$file} join "\n", @ret;
    close $file;

    infof "カタロムCSVを出力しました。(exhibition=%s, run_by=%s, cond=%s)", $e, $self->run_by, ddf($self->where);
    $self;
}

1;
