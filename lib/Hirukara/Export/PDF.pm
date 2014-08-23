package Hirukara::Export::PDF;
use Mouse;
use Log::Minimal;
use File::Temp;
use Text::Xslate;
use Hirukara::Util;
use Time::Piece;

has checklists => ( is => 'rw', isa => 'ArrayRef' );

has title => ( is => 'rw', isa => 'Str' );

has split_by => ( is => 'rw', isa => 'Str' );

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

has pdf_file => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new });

my %TEMPLATES = (
    default => 'pdf/simple.tt',
    order   => 'pdf/order.tt',
);

my %CONVERTER = (
    default => sub { shift },
    order   => sub {
        my $checks = shift;
        my %orders;

        for my $data (@$checks) {
            my $favorite = $data->{favorite};

            for my $f (@$favorite)    {   
                $orders{$f->member_id}->{favorite} = $f; 
                push @{$orders{$f->member_id}->{rows}}, $data;
            }   
        } 

        \%orders;
    },
);

sub get_extension { "pdf" }

sub process {
    my $c = shift;
    my $checklist = $c->checklists;

    my $type = $c->split_by || 'default';

    ## wkhtmltopdf don't read file unless file extension is '.html'
    my $html = File::Temp->new(SUFFIX => '.html');
    my $pdf  = $c->pdf_file;
    close $pdf;

    my $html_path = $html->filename;
    my $pdf_path  = $pdf->filename;
    my $template  = $TEMPLATES{$type};
    my $converted = $CONVERTER{$type}->($checklist);

    print $html $c->template->render($template, { checklists => $converted, title => $c->title });
    close $html;

    infof "PDF_OUTPUT: type=%s, file=%s, in=%s, out=%s", $type, $template, $html_path, $pdf_path;

    system "wkhtmltopdf", $html_path, $pdf_path;
    open my $out, $pdf_path or die "$pdf_path : $!";
    $out;
}

1;
