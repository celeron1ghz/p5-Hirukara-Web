package Hirukara::Command::CircleOrder::Exporter;
use Moose::Role;

use Text::Xslate();
use Time::Piece();
use File::Temp();
use Encode();

has file   => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );
has run_by => ( is => 'ro', isa => 'Str', required => 1 );

requires 'extension';

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

sub get_all_prefetched {
    my $self    = shift;
    my $table   = $self->db->schema->get_table('circle');
    my $columns = $table->field_names;
    my $cond    = $self->hirukara->get_condition_object(@_);
    my $opt     = { order_by => 'day ASC, circle_sym ASC, circle_num ASC, circle_flag ASC' }; 

    my ($sql, @bind) = $self->db->query_builder->select('circle', $columns, $cond->{condition}, $opt);
    my $it = $self->db->select_by_sql($sql, \@bind, {
        table_name => 'circle',
        columns    => $columns,
        prefetch   => [ { 'assigns' => [ {'assign_list' => ['member']}] }, { circle_books => ['circle_orders'] } ],
    }); 
    wantarray ? ($it,$cond) : $it;
}

1;
