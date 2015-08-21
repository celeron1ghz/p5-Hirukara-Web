package Hirukara::Command::Checklist::Bulkexport;
use Moose;
use Hirukara::Command::Checklist::Export;
use Hirukara::Parser::CSV;
use Hash::MultiValue;
use Path::Tiny;
use File::Temp 'tempdir';
use Archive::Zip;
use Encode;
use Parallel::ForkManager;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self    = shift;
    my $e       = $self->exhibition;
    my @lists   = $self->database->search('assign_list' => { comiket_no => $e })->all;
    my $tempdir = path(tempdir());
    my $start   = time;
    $self->logger->info("チェックリストの一括出力を行います。" => [
        exhibition       => $e,
        member_id         => $self->member_id,
        assign_list_count => scalar @lists,
        dir               =>$tempdir,
    ]);

    my @file_types = (
        {
            type     => 'pdf_order',
            filename => sub {
                my($list,$name) = @_;
                $tempdir->path(sprintf "%s (%s)[ORDER].pdf", map { s!/!-!g; encode_utf8 $_ } $list->name, $name);
            },
        },
        {
            type     => 'pdf_distribute',
            filename => sub {
                my($list,$name) = @_;
                $tempdir->path(sprintf "%s (%s)[DISTRIBUTE].pdf", map { s!/!-!g; encode_utf8 $_ } $list->name, $name);
            },
        },
        {
            type     => 'checklist',
            filename => sub {
                my($list,$name) = @_;
                $tempdir->path(sprintf "%s (%s).csv", map { s!/!-!g; encode_utf8 $_ } $list->name, $name);
            },
        },
    );

    my @jobs;
    for my $list (@lists)   {
        my $h   = Hash::MultiValue->new(assign => $list->id);

        for my $type (@file_types)   {
            my $ret = Hirukara::Command::Checklist::Export->new(
                database     => $self->database,
                logger       => $self->logger,
                type         => $type->{type},
                where        => $h,
                exhibition   => $self->exhibition,
                template_var => { member_id => 'aaaa' },
                member_id    => $self->member_id,
            );

            my $member   = $self->database->single(member => { member_id => $list->member_id });
            my $name     = $member ? $member->member_name : 'NOT_ASSIGNED';
            my $file     = path($ret->{file});
            my $filename = $type->{filename}->($list,$name);

            push @jobs, {
                object   => $ret,
                tempfile => $file,
                dest     => $filename,
            };
        }
    }

    my $pm  = Parallel::ForkManager->new(10);
    my $zip = Archive::Zip->new;

    for my $j (@jobs)   {
        $pm->start and next;
        $j->{object}->run;
        $pm->finish;
    }

    $pm->wait_all_children;

    for my $j (@jobs)   {
        my $obj = $j->{object};
        my $tmp = $j->{tempfile};
        my $dst = $j->{dest};
        $tmp->move($dst);
        $zip->addFile("$dst", $dst->basename);
    }

    my $archive = File::Temp::tempnam(tempdir(), "hirukara");
    $zip->writeToFileNamed($archive);
    my $end = time;
    $self->logger->info("チェックリストの一括出力を行います。", [ path => $archive, elpased => $end - $start ]);;
    return $archive;
}

1;
