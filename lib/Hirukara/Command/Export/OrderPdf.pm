package Hirukara::Command::Export::OrderPdf;
use utf8;
use Moose;
use Hirukara::Exception;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exporter';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub extension { 'pdf' }

sub run {
    my $self = shift;
    my $mid  = $self->member_id;
    my $mem  = $self->db->single(member => { member_id => $mid });
    my $it   = $self->get_all_prefetched({ member_id => $mid});
    my %dist;
    my @circles = $it->all or Hirukara::Checklist::NoSuchCircleInListException->throw(list => "mid=$mid");

    for my $circle (@circles)   {
        my @assigns = $circle->assigns;

        if (@assigns)   {
            for my $a (@assigns)    {
                my $list = $a->assign_list;
                my $list_id = $list->id;
                $dist{$list_id} ||= {};
                $dist{$list_id}->{assign_list} = $list;
                $dist{$list_id}->{rows} ||= [];
                push @{$dist{$list_id}->{rows}}, $circle;
            }
        } else {
            $dist{'NOT_ASSIGNED'} ||= {};
            $dist{'NOT_ASSIGNED'}->{rows} ||= [];
            push @{$dist{'NOT_ASSIGNED'}->{rows}}, $circle;
        }
    }

    $self->generate_pdf('pdf/order.tt', { member => $mem, dist => \%dist });

    my $e = $self->hirukara->exhibition;
    infof "発注リストを出力しました。(exhibition=%s, run_by=%s, member_id=%s)", $e, $self->run_by, $mid;
    $self;
}

1;
