package Hirukara::Command::Checklist::Export;
use utf8;
use Moose;
use File::Temp;
use Encode;
use JSON;
use Time::Piece; ## using in template
use Hirukara::Parser::CSV;
use Hirukara::SearchCondition;
use Hirukara::Exception;
use Text::Xslate;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has file => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );

has type         => ( is => 'ro', isa => 'Str', required => 1 );
has where        => ( is => 'ro', isa => 'Hash::MultiValue', required => 1 );
has template_var => ( is => 'ro', isa => 'HashRef', required => 1 );
has member_id    => ( is => 'ro', isa => 'Str', required => 1 );

sub __generate_pdf  {
    my($self,$template,$converted) = @_;
    my $xslate = Text::Xslate->new(
        path => './tmpl/',
        syntax => 'TTerse',
        function => {
            time => sub { Time::Piece->new },
            sprintf => \&CORE::sprintf,
        },
    );

    ## wkhtmltopdf don't read file unless file extension is '.html'
    my $html = File::Temp->new(SUFFIX => '.html');
    my $pdf  = $self->file;
    close $pdf;

    print $html encode_utf8 $xslate->render($template, { checklists => $converted, %{$self->template_var} });
    close $html;

    system "wkhtmltopdf", "--quiet", $html->filename, $pdf->filename;
}
 

my %TYPES = (
    checklist  => {
        template   => 'pdf/simple.tt',
        extension => 'csv',
        generator  => sub {
            my($self,$converted) = @_;
            my $e = $self->exhibition;
            $e =~ /^ComicMarket\d+$/ or Hirukara::Checklist::NotAComiketException->throw("'$e' is not a comiket");

            my @ret = (
                sprintf("Header,ComicMarketCD-ROMCatalog,%s,UTF-8,Windows 1.86.1", $e),
            );

            for my $circle (@$converted) {
                my $raw = decode_json $circle->serialized;
                my $row = Hirukara::Parser::CSV::Row->new($raw);
                my $fav = $circle->checklists;
                my @comment;
                my $cnt = 0;

                for my $f (@$fav)   {
                    $cnt += ($f->count || 0);

                    if ($f->comment)    {
                        push @comment, sprintf "%s=[%s]", $f->member->member_name, $f->comment;
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

            my $file = $self->file;
            print {$file} join "\n", @ret;
            close $file;
        },
        
    },

    pdf_buy => {
        extension => 'pdf',
        generator => sub {
            my($self,$checklist) = @_;
            $self->__generate_pdf('pdf/buy.tt', $checklist);
        },
    },

    pdf_distribute  => {
        extension => 'pdf',
        generator => sub {
            my($self,$checklist) = @_;
            my %orders;
    
            for my $data (@$checklist) {
                my $checklists = $data->checklists;
    
                for my $chk (@$checklists)    {   
                    $orders{$chk->member_id}->{member} = $chk->member; 
                    push @{$orders{$chk->member_id}->{rows}}, $data;
                }   
            } 
    
            $self->__generate_pdf('pdf/distribute.tt', \%orders);
        },
    },

    pdf_order => {
        extension => 'pdf',
        generator => sub {
            my($self,$checklist) = @_;
            my %assigns;

            for my $data (@$checklist) {
                my $assign = $data->assigns;
    
                for my $a (@$assign)    {
                    $assigns{$a->id}->{assign} = $a;
                    push @{$assigns{$a->id}->{rows}}, $data;
                }
            }
    
            $self->__generate_pdf('pdf/order.tt', \%assigns);
        },
    },
);

sub run {
    my $self = shift;
    my $t    = $self->type;
    my $type = $TYPES{$t} or Hirukara::Checklist::InvalidExportTypeException->throw("unknown type '$t'");
    my $cond = $self->hirukara->get_condition_object($self->where);
    $self->template_var->{title} = $cond->{condition_label};

    my $checklist = $self->db->search_all_joined($cond->{condition});

    my $tmpl = $type->{template};
    my $meth = $type->{generator};
    my $ext  = $type->{extension};
    $meth->($self,$checklist);

    $self->actioninfo("チェックリストをエクスポートします。",
        type      => $t,
        member_id => $self->member_id,
        cond      => ddf($self->where),
    );

    {
        exhibition => $self->exhibition,
        extension  => $ext,
        file       => $self->file,
    };
}

1;
