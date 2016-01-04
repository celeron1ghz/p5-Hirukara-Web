package Hirukara::Command::Export::BuyPdf;
use utf8;
use Moose;
use Encode;
use Hirukara::Exception;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exporter';

has where => ( is => 'ro', isa => 'Hash::MultiValue', required => 1 );

sub extension { 'pdf' }

sub run {
    my $self = shift;
    my($it,$cond) = $self->get_all_prefetched($self->where);
    my @circles = $it->all or Hirukara::Checklist::NoSuchCircleInListException->throw(list => "pdf, cond=$cond->{condition_label}");
    $self->generate_pdf('pdf/buy.tt', { circles => \@circles, label => $cond->{condition_label} });

    my $e = $self->hirukara->exhibition;
    infof encode_utf8("購買リストを出力しました。(exhibition=%s, run_by=%s, cond=%s)"), $e, $self->run_by, ddf($self->where);
    $self;
}

__PACKAGE__->meta->make_immutable;
