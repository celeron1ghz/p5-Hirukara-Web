package Hirukara::Command::CircleOrder::Export::BuyPdf;
use utf8;
use Moose;
use File::Temp;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition', 'Hirukara::Command::CircleOrder::Exporter';

has file  => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );
has where => ( is => 'ro', isa => 'Hash::MultiValue', required => 1 );

sub run {
    my $self = shift;
    my $table      = $self->db->schema->get_table('circle');
    my $columns    = $table->field_names;
    my $opt        = {}; 

    my $cond = $self->hirukara->get_condition_object($self->where);
    my ($sql, @bind) = $self->db->query_builder->select('circle', $columns, $cond->{condition}, $opt);
    my $it = $self->db->select_by_sql($sql, \@bind, {
        table_name => 'circle',
        columns    => $columns,
        prefetch   => [ { 'assigns' => [ {'assign_list' => ['member']}] }, { circle_books => ['circle_orders'] } ],
    });

    $self->generate_pdf('pdf/buy.tt', { checklists => [$it->all] });

    {
        exhibition => $self->exhibition,
        extension  => 'pdf',
        file       => $self->file,
    };
}

1;
