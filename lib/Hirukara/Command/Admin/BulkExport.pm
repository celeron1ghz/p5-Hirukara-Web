package Hirukara::Command::Admin::BulkExport;
use utf8;
use Moose;
use Hirukara::Parser::CSV;
use Hash::MultiValue;
use Path::Tiny;
use File::Temp 'tempdir';
use Archive::Zip;
use Encode;
use Parallel::ForkManager;
use Try::Tiny;
use Log::Minimal;
use Encode;
use Time::Piece;

use Hirukara::Command::Export::BuyPdf;
use Hirukara::Command::Export::OrderPdf;
use Hirukara::Command::Export::ComiketCsv;

with 'MooseX::Getopt', 'Hirukara::Command';

has slack  => ( is => 'ro', isa => 'Hirukara::Slack', required => 1 );
has run_by => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self    = shift;
    my $e       = $self->hirukara->exhibition;
    my @lists   = $self->db->search('assign_list' => { comiket_no => $e })->all;
    my $tempdir = path(tempdir());
    my $start   = time;
    my @jobs;

    for my $member ($self->db->select('member')->all)   {
        push @jobs, {
            object => Hirukara::Command::Export::OrderPdf->new(
                hirukara   => $self->hirukara,
                exhibition => $e,
                member_id  => $member->member_id,
                run_by     => $self->run_by,
            ),
            dest => $tempdir->path(sprintf "%s [ORDER].pdf", $member->member_id),
        };
    }

    for my $list (@lists)   {
        my $name      = $list->name;
        my $member_id = $list->member_id || 'NOT_ASSIGNED';

        for ($name, $member_id) {
            s!/!-!g;
            $_ = encode_utf8 $_;
        }

        push @jobs, {
            object => Hirukara::Command::Export::BuyPdf->new(
                hirukara   => $self->hirukara,
                exhibition => $e,
                where      => Hash::MultiValue->new(assign => $list->id),
                run_by     => $self->run_by,
            ),
            dest => $tempdir->path(sprintf "%s (%s) [BUY].pdf", $name, $member_id),
        },{
            object => Hirukara::Command::Export::ComiketCsv->new(
                hirukara   => $self->hirukara,
                exhibition => $e,
                where      => Hash::MultiValue->new(assign => $list->id),
                run_by     => $self->run_by,
            ),
            dest => $tempdir->path(sprintf "%s (%s).csv", $name, $member_id),
        };
    }

    $self->slack->post(
        "チェックリスト一括出力 ファイル生成開始 ($e:$$)",
        sprintf "%s個のチェックリストを生成予定です。(run_by=%s)", scalar @jobs, $self->run_by,
    );

    $self->actioninfo("チェックリストの一括出力を行います。" => 
        exhibition => $e,
        list_count => scalar @jobs,
        run_by     => $self->run_by,
    );

    my $pm  = Parallel::ForkManager->new(8);
    my $zip = Archive::Zip->new;

    for my $j (@jobs)   {
        $pm->start and next;
        try {
            $j->{object}->run;
        } catch {
            infof "%s", encode_utf8 $_;
            undef $_;
        };
        $pm->finish;
    }

    $pm->wait_all_children;

    my $created = 0;
    for my $j (@jobs)   {
        my $obj = $j->{object};
        my $tmp = path($obj->file);
        my $dst = $j->{dest};

        -s $tmp or next;
        $tmp->move($dst);
        $zip->addFile("$dst", $dst->basename);
        $created++;
    }

    my $archive = File::Temp::tempnam(tempdir(), "hirukara");
    $zip->writeToFileNamed($archive);
    my $end = time;

    $self->slack->post(
        "チェックリスト一括出力 ファイル生成終了 ($e:$$)",
        sprintf "作成したチェックリストのファイルサイズは%s byteで%s個のチェックリストが含まれています。"
                . "作成に%s秒かかりました。%s個のファイルはチェックリストが空のため出力していません。",
            -s $archive, $created, $end - $start, @jobs - $created
    );

    my $filename = sprintf "[%s] %s_%s.zip", 'hirukara', $self->hirukara->exhibition, localtime->strftime('%Y%m%d_%H%M%S');

    $self->slack->upload(
        file     => $archive,
        filename => $filename,
        title    => encode_utf8('チェックリスト一括出力ファイル'),
    );

    $self->actioninfo("チェックリストの一括出力を行いました。", => 
        exhibition => $e,
        list_count => scalar @jobs,
        run_by     => $self->run_by,
        elpased    => $end - $start
    );

    return $archive;
}

__PACKAGE__->meta->make_immutable;
