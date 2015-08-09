package Hirukara::Command::Checklist::Bulkexport;
use Moose;
use Hirukara::Command::Checklist::Export;
use Hirukara::Parser::CSV;
use Hash::MultiValue;
use Log::Minimal;
use Path::Tiny;
use File::Temp 'tempdir';
use Archive::Zip;
use Encode;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

sub run {
    my $self = shift;
    my $e    = $self->exhibition;

    my @lists   = $self->database->search('assign_list' => { comiket_no => $e })->all;
    my $tempdir = path(tempdir());
    my $zip     = Archive::Zip->new;
    infof "BULK_EXPORT: exhibition=%s, assign_list_count=%s, dir=%s", $e, scalar @lists, $tempdir;

    my @file_types = (
        {
            type     => 'pdf',
            split_by => 'assign',
            filename => sub {
                my($list,$name) = @_;
                $tempdir->path(sprintf "%s (%s)[ASSIGN].pdf", map { s!/!-!g; encode_utf8 $_ } $list->name, $name);
            },
        },
        {
            type     => 'pdf',
            split_by => 'order',
           filename => sub {
                my($list,$name) = @_;
                $tempdir->path(sprintf "%s (%s)[ORDER].pdf", map { s!/!-!g; encode_utf8 $_ } $list->name, $name);
            },
        },
        {
            type     => 'checklist',
            split_by => 'checklist',
            filename => sub {
                my($list,$name) = @_;
                $tempdir->path(sprintf "%s (%s).csv", map { s!/!-!g; encode_utf8 $_ } $list->name, $name);
            },
        },
    );

    for my $list (@lists)   {
        my $h   = Hash::MultiValue->new(assign => $list->id);

        for my $type (@file_types)   {
            my $ret = Hirukara::Command::Checklist::Export->new(
                type         => $type->{type},
                split_by     => $type->{split_by},
                database     => $self->database,
                where        => $h,
                exhibition   => $self->exhibition,
                template_var => { member_id => 'aaaa' },
            )->run;

            my $member   = $self->database->single(member => { member_id => $list->member_id });
            my $name     = $member ? $member->member_name : 'NOT_ASSIGNED';
            my $file     = path($ret->{file});
            my $filename = $type->{filename}->($list,$name);
            $file->move($filename);
            $zip->addFile("$filename", $filename->basename);
        }
    }

    my $archive = File::Temp->new;
    $zip->writeToFileNamed("$archive");
    infof "BULK_EXPORT: path=%s", $archive;
    return $archive;
}

1;
