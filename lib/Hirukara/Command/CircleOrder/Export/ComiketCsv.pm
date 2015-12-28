package Hirukara::Command::CircleOrder::Export::ComiketCsv;
use utf8;
use Moose;
use File::Temp;
use Encode;
use JSON;
use Hirukara::Parser::CSV;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has file  => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );
has where => ( is => 'ro', isa => 'Hash::MultiValue', required => 1 );

sub run {
    my $self = shift;
    my $table      = $self->db->schema->get_table('circle');
    my $columns    = $table->field_names;
    my $opt        = {}; 

    my $cond = $self->hirukara->get_condition_object($self->where);
    my ($sql, @bind) = $self->db->query_builder->select('circle', $columns, $cond->{condition}, $opt);
    my $list = $self->db->select_by_sql($sql, \@bind, {
        table_name => 'circle',
        columns    => $columns,
        prefetch   => [ { 'assigns' => [ {'assign_list' => ['member']}] }, { circle_books => ['circle_orders'] } ],
    }); 

    my $e = $self->exhibition;
    $e =~ /^ComicMarket\d+$/ or Hirukara::Checklist::NotAComiketException->throw(exhibition => $e);

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

    {
        exhibition => $self->exhibition,
        extension  => 'csv',
        file       => $self->file,
    };
}

1;
