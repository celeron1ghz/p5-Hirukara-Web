package Hirukara::Export::PDF;
use Mouse;
use Log::Minimal;
use File::Temp;
use Text::Xslate;
use Hirukara::Util;

has checklists => ( is => 'rw', isa => 'ArrayRef' );

has template => ( is => 'ro', isa => 'Text::Xslate', default => sub {
    Text::Xslate->new(
        path => './tmpl/',
        syntax => 'TTerse',
        function => {
            circle_space => Hirukara::Util->can('get_circle_space')
        },
    );
});

has pdf_file => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new });

sub get_extension { "pdf" }

sub process {
    my $c = shift;
    my $checklist = $c->checklists;

    ## wkhtmltopdf don't read file unless file extension is '.html'
    my $html = File::Temp->new(SUFFIX => '.html');
    my $pdf  = $c->pdf_file;
    close $pdf;

    my $html_path = $html->filename;
    my $pdf_path  = $pdf->filename;

    print $html $c->template->render("assign_me.tt", { checklists => $checklist });
    close $html;

    infof "PDF_OUTPUT: in=%s, out=%s", $html_path, $pdf_path;

    system "wkhtmltopdf", $html_path, $pdf_path;
    open my $out, $pdf_path or die "$pdf_path : $!";
    $out;
}

1;
