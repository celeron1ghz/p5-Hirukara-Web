package Hirukara::Command::CircleOrder::Export::OrderPdf;
use utf8;
use Moose;
use File::Temp;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition', 'Hirukara::Command::CircleOrder::Exporter';

has file      => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );
has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $cond = $self->hirukara->get_condition_object({ member_id => $self->member_id });
    my $mem  = $self->db->single(member => { member_id => $self->member_id });
    my %dist;

    my $table      = $self->db->schema->get_table('circle');
    my $columns    = $table->field_names;
    my $opt        = {};

    my ($sql, @bind) = $self->db->query_builder->select('circle', $columns, $cond->{condition}, $opt);
    my $it = $self->db->select_by_sql($sql, \@bind, {
        table_name => 'circle',
        columns    => $columns,
        prefetch   => [ { 'assigns' => [ {'assign_list' => ['member']}] }, { circle_books => ['circle_orders'] } ],
    }); 

    for my $circle ($it->all)   {
        for my $a ($circle->assigns)    {
            #for my $o ($b->circle_orders)   {
                my $list = $a->assign_list;
                my $list_id = $list->id;
                $dist{$list_id} ||= {};
                $dist{$list_id}->{assign_list} = $list;
                $dist{$list_id}->{rows} ||= [];
                push @{$dist{$list_id}->{rows}}, $circle;
            #}
        }
    }

    $self->generate_pdf('pdf/order.tt', { member => $mem, dist => \%dist });

    {
        exhibition => $self->exhibition,
        extension  => 'pdf',
        file       => $self->file,
    };
}

1;
