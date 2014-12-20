package Hirukara::Export::PDF;
use Mouse;
use Log::Minimal;
use File::Temp;
use Text::Xslate;
use Hirukara::Util;
use Time::Piece;
use Encode;

with 'Hirukara::Export';

has split_by => ( is => 'rw', isa => 'Str' );
has template_var => ( is => 'rw', isa => 'HashRef', default => sub { +{} } );

has template => ( is => 'ro', isa => 'Text::Xslate', default => sub {
    Text::Xslate->new(
        path => './tmpl/',
        syntax => 'TTerse',
        function => {
            circle_space => Hirukara::Util->can('get_circle_space'),
            time         => sub { Time::Piece->new },
        },
    );
});

my %TEMPLATES = (
    checklist => 'pdf/simple.tt',
    order     => 'pdf/order.tt',
    assign    => 'pdf/assign.tt',
);

my %CONVERTER = (
    checklist => sub { shift },
    order => sub {
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
    assign => sub {
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

);

sub get_extension { "pdf" }

sub process {
    my $c = shift;
    my $checklist = $c->checklists;
    my $type      = $c->split_by || 'checklist';

    ## wkhtmltopdf don't read file unless file extension is '.html'
    my $html = File::Temp->new(SUFFIX => '.html');
    my $pdf  = $c->file;
    close $pdf;

    my $html_path = $html->filename;
    my $pdf_path  = $pdf->filename;
    my $template  = $TEMPLATES{$type};
    my $converted = $CONVERTER{$type}->($checklist);

    print $html encode_utf8 $c->template->render($template, { checklists => $converted, %{$c->template_var} });
    close $html;

    infof "PDF_OUTPUT: type=%s, file=%s, in=%s, out=%s", $type, $template, $html_path, $pdf_path;

    system "wkhtmltopdf", "--quiet", $html_path, $pdf_path;
}

1;
