package Hirukara::Command::Checklist::Export;
use Moose;
use File::Temp;
use Encode;
use JSON;
use Time::Piece;

with 'MooseX::Getopt', 'Hirukara::Command';

has file         => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );
has type         => ( is => 'ro', isa => 'Str', required => 1 );
has split_by     => ( is => 'ro', isa => 'Str', required => 1 );
has checklists   => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has template_var => ( is => 'ro', isa => 'HashRef', required => 1 );

my %EXPORT_TYPE = ( 
    checklist => {
        class_name => "ComiketCsv",
        extension  => "csv",
        split      => 0,
        generator  => sub {
            my($self,$converted,$output_type) = @_;
            my @ret = (
                sprintf("Header,ComicMarketCD-ROMCatalog,ComicMarket87,UTF-8,Windows 1.86.1"),
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

            print {$self->file} join "\n", @ret;
        },
    },

    pdf => {
        class_name => "PDF",
        extension  => "pdf",
        split      => 1,
        generator => sub {
            my($self,$converted,$output_type) = @_;
            my $template = Text::Xslate->new(
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

            print $html encode_utf8 $template->render($output_type->{template}, { checklists => $converted, %{$self->template_var} });
            close $html;

            system "wkhtmltopdf", "--quiet", $html->filename, $pdf->filename;

        },
    },
);

my %TYPES = (
    checklist =>    {
        template  => 'pdf/simple.tt',
        converter => sub { shift },
    },

    order => {
        template  => 'pdf/order.tt',
        converter => sub {
            my $checks = shift;
            my %orders;
    
            for my $data (@$checks) {
                my $checklists = $data->checklists;
    
                for my $chk (@$checklists)    {   
                    $orders{$chk->member_id}->{member} = $chk->member; 
                    push @{$orders{$chk->member_id}->{rows}}, $data;
                }   
            } 
    
            \%orders;
        },
    },

    assign => {
        template  => 'pdf/assign.tt',
        converter => sub {
            my $checks = shift;
            my %assigns;

            for my $data (@$checks) {
                my $assign = $data->assigns;
    
                for my $a (@$assign)    {
                    $assigns{$a->id}->{assign} = $a;
                    push @{$assigns{$a->id}->{rows}}, $data;
                }
            }
    
            \%assigns;
        },
    },
);

sub run {
    my $self = shift;
    my $checklist     = $self->checklists;

    my $template_type = $self->split_by || 'checklist';
    my $export_type   = $EXPORT_TYPE{$self->type} or die "unknown type " . $self->type;
    my $output_type   = $TYPES{$template_type} or die "no such type '$template_type'";

    if ($export_type->{split})  {
        $checklist = $output_type->{converter}->($checklist);
    }

    $export_type->{generator}->($self,$checklist,$output_type);
    $self->action_log([ file_type => $export_type->{class_name}, template_type => $template_type, split_by => $self->split_by, file => $self->file->filename ]);

    {
        extension => $export_type->{extension},
        file      => $self->file,
    };
}

1;
