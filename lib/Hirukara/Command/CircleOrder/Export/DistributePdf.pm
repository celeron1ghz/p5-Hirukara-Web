package Hirukara::Command::CircleOrder::Export::DistributePdf;
use utf8;
use Moose;
use File::Temp;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition', 'Hirukara::Command::CircleOrder::Exporter';

has assign_list_id => ( is => 'ro', isa => 'Str', required => 1 );

sub extension { 'pdf' }

sub run {
    my $self = shift;
    my $list = $self->db->single(assign_list => {
        id => $self->assign_list_id,
        comiket_no => $self->exhibition,
    }, {
        prefetch => [ { 'assigns' => { 'circle' => { circle_books => ['circle_orders'] } } } ],
    });
    my %dist;

    for my $a ($list->assigns)  {
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

    my $e = $self->hirukara->exhibition;
    $self->actioninfo("分配リストを出力しました。", exhibition => $e, list_id => $self->assign_list_id);
    $self;
}

1;