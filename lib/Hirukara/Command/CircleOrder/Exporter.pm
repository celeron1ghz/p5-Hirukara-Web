package Hirukara::Command::CircleOrder::Exporter;
use Moose::Role;

use Text::Xslate();
use Time::Piece();
use File::Temp();
use Encode();

has file => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );

sub generate_pdf  {
    my $self = shift;
    my $template = shift;
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

    print $html Encode::encode_utf8 $xslate->render($template, @_);
    close $html;

    system "wkhtmltopdf", "--quiet", $html->filename, $pdf->filename;
}
 

1;
