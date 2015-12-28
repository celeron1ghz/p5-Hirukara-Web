package Hirukara::Command::CircleOrder::Export::BuyPdf;
use utf8;
use Moose;
use File::Temp;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::CircleOrder::Exporter';

has where => ( is => 'ro', isa => 'Hash::MultiValue', required => 1 );

sub extension { 'pdf' }

sub run {
    my $self = shift;
    my $it = $self->get_all_prefetched($self->where);
    $self->generate_pdf('pdf/buy.tt', { checklists => [$it->all] });
    $self;
}

1;
