package Hirukara::Command::Export::DistributePdf;
use utf8;
use Moose;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exporter';

has assign_list_id => ( is => 'ro', isa => 'Str', required => 1 );

sub extension { 'pdf' }

sub run {
    my $self = shift;
    my $e    = $self->hirukara->exhibition;
    my $id   = $self->assign_list_id;
    my $list = $self->db->single(assign_list => {
        id => $self->assign_list_id,
        comiket_no => $e,
    }, {
        prefetch => [ { 'assigns' => { 'circle' => { circle_books => ['circle_orders'] } } } ],
    });
    my %dist;
    my @assigns = $list->assigns or Hirukara::Checklist::NoSuchCircleInListException->throw(list => "aid=$id");

    for my $a (@assigns)    {
        my $circle = $a->circle;
        my %pushed;

        for my $b ($a->circle->circle_books)    {
            for my $o ($b->circle_orders)   {
                next if $pushed{$o->member_id};
                $pushed{$o->member_id}++;

                my $member_id = $o->member_id;
                $dist{$member_id} ||= {};
                $dist{$member_id}->{member} = $o->member;
                $dist{$member_id}->{rows} ||= [];
                push @{$dist{$member_id}->{rows}}, $circle;
            }
        }
    }

    $self->generate_pdf('pdf/distribute.tt', { list => $list, dist => \%dist });

    infof "分配リストを出力しました。(exhibition=%s, run_by=%s, list_id=%s)", $e, $self->run_by, $self->assign_list_id;
    $self;
}

1;
