package Hirukara::Command::CircleOrder::Export::OrderPdf;
use utf8;
use Moose;
use File::Temp;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::CircleOrder::Exporter';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub extension { 'pdf' }

sub run {
    my $self = shift;
    my $mem  = $self->db->single(member => { member_id => $self->member_id });
    my $it   = $self->get_all_prefetched({ member_id => $self->member_id });
    my %dist;

    for my $circle ($it->all)   {
        for my $a ($circle->assigns)    {
            my $list = $a->assign_list;
            my $list_id = $list->id;
            $dist{$list_id} ||= {};
            $dist{$list_id}->{assign_list} = $list;
            $dist{$list_id}->{rows} ||= [];
            push @{$dist{$list_id}->{rows}}, $circle;
        }
    }

    $self->generate_pdf('pdf/order.tt', { member => $mem, dist => \%dist });
    $self;
}

1;
