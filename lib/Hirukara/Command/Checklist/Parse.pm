package Hirukara::Command::Checklist::Parse;
use utf8;
use Moose;
use Digest::MD5 'md5_hex';
use Encode;
use Hirukara::Parser::CSV;
use Hirukara::Command::Circle::Create;
use Hirukara::Exception;
use Path::Tiny;
use File::Copy;

with 'MooseX::Getopt', 'Hirukara::Command';

has exhibition    => ( is => 'ro', isa => 'Str', required => 1 );
has csv_file      => ( is => 'ro', isa => 'Str', required => 1 );
has member_id     => ( is => 'ro', isa => 'Str', required => 1 );
has merge_results => ( is => 'rw', isa => 'HashRef' );
has checklist_dir => ( is => 'ro', isa => 'Path::Tiny', default => sub { path('./checklist')->absolute } );

my %DAY_LOOKUP = (
    ComicMarket85 => { "日" => 1, "月" => 2, "火" => 3, "×" => 0 },
    ComicMarket86 => { "金" => 1, "土" => 2, "日" => 3, "×" => 0 },
    ComicMarket87 => { "日" => 1, "月" => 2, "火" => 3, "×" => 0 },
    ComicMarket88 => { "金" => 1, "土" => 2, "日" => 3, "×" => 0 },
    ComicMarket89 => { "火" => 1, "水" => 2, "木" => 3, "×" => 0 },
);


sub __get_day   {
    my($circle) = @_;
    my $no = $circle->comiket_no;
    my $comiket = $DAY_LOOKUP{$no} or die "$no not found";
    return $comiket->{$circle->day};
}

sub __get_area  {
    my($circle) = @_;
    my $area = $circle->area;
    $area =~ s/^(.+\d+).*?$/$1/;
    return $area;
}


sub run {
    my($self) = @_;
    $self->exhibition =~ /^ComicMarket\d+$/ or Hirukara::Checklist::NotAComiketException->throw(exhibition => $self->exhibition);

    my $database = $self->db;
    my $member_id = $self->member_id;
    my $in_database = {};
    my $in_checklist = {};
    my $diff = {};

    ## creating backup
    my $dest = $self->checklist_dir->child(sprintf "%s_%s.csv", time, $self->member_id);
    copy +$self->csv_file, $dest;

    ## parsing csv
    my $csv = Hirukara::Parser::CSV->read_from_file($self->csv_file);
    my $comiket_no = $csv->comiket_no;
    my $exhibition = $self->exhibition;

    $comiket_no eq $exhibition
        or Hirukara::CSV::NotActiveComiketChecklistUploadedException->throw(want_exhibition => $exhibition, given_exhibition => $comiket_no);

    local *Hirukara::Parser::CSV::Row::comiket_no = sub { $csv->comiket_no }; ## oops :-(

    ## remove rejected circle
    my @csv_circles = grep { __get_day($_) ne "0" } @{$csv->circles};

    for my $csv_circle (@csv_circles)  {
        my $circle = Hirukara::Command::Circle::Create->new(
            hirukara      => $self->hirukara,
            comiket_no    => $csv->comiket_no,
            circle_name   => $csv_circle->circle_name,
            circle_author => $csv_circle->circle_author,
            day           => __get_day($csv_circle),
            area          => __get_area($csv_circle),
            circle_sym    => $csv_circle->circle_sym,
            circle_num    => $csv_circle->circle_num,
            circle_flag   => $csv_circle->circle_flag ? "b" : "a",
            circlems      => $csv_circle->circlems,
            url           => $csv_circle->url,
            circle_type   => 0,

            map { $_ => $csv_circle->$_ } qw/
                type
                serial_no
                color
                page_no
                cut_index
                genre
                circle_kana
                publish_info
                mail
                remark
                comment
                map_x
                map_y
                map_layout
                update_info
                circlems
                rss
                rss_info
            /,
        );

        my $md5   = $circle->id;
        my $in_db = $database->single('circle', { id => $md5 });

        if (!$in_db)   {
            $in_db = $circle->run;
        }

        $in_checklist->{$md5} = { circle => $in_db->get_columns, csv => $csv_circle };
        delete $circle->{database};
    }

    my $it = $database->select_joined(circle => [
        checklist => { 'circle.id' => 'checklist.circle_id' },
    ],{
        'checklist.member_id' => $member_id,
        'circle.comiket_no'   => $self->exhibition,
    }, {});

    for my $row ($it->all) {
        my $circle = $row->circle;
        my $chk    = $row->checklist;
        $in_database->{$chk->circle_id} = { circle => $circle->get_columns, db => $chk->get_columns };
    }

    while ( my($md5,$data) = each %$in_checklist )  {
        if (my $db = $in_database->{$md5}) {
            $data->{db} = $db->{db};
            $diff->{exist}->{$md5} = $data;
        } else {
            $diff->{create}->{$md5} = $data;
        }
    }

    while ( my($md5,$data) = each %$in_database )  {
        if (!$in_checklist->{$md5}) {
            $diff->{delete}->{$md5} = $data;
        }
    }

    $self->merge_results($diff);
    $self->actioninfo("チェックリストがアップロードされました。",
        member_id  => $member_id,
        exhibition => $csv->comiket_no,
        checklist  => scalar keys %$in_checklist,
        database   => scalar keys %$in_database,
        exist      => scalar keys %{$diff->{exist}},
        create     => scalar keys %{$diff->{create}},
        delete     => scalar keys %{$diff->{delete}},
    );

    $self;
}

1;
