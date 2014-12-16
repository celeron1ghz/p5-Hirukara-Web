package Hirukara::Command::Checklist::Merge;
use utf8;
use Mouse;
use Digest::MD5 'md5_hex';
use Log::Minimal;
use Encode;
use Hirukara::Constants::Area;
use Hirukara::Command::Circle::Create;

with 'MouseX::Getopt', 'Hirukara::Command';

has csv           => ( is => 'ro', isa => 'Hirukara::Parser::CSV', required => 1 );
has database      => ( is => 'ro', isa => 'Teng', required => 1 );
has member_id     => ( is => 'ro', isa => 'Str', required => 1 );
has merge_results => ( is => 'rw', isa => 'HashRef' );

my %DAY_LOOKUP = (
    ComicMarket85 => { "日" => 1, "月" => 2, "火" => 3, "×" => 0 },
    ComicMarket86 => { "金" => 1, "土" => 2, "日" => 3, "×" => 0 },
    ComicMarket87 => { "日" => 1, "月" => 2, "火" => 3, "×" => 0 },
);

sub __get_day   {
    my($circle) = @_;
    my $no = $circle->comiket_no;
    my $comiket = $DAY_LOOKUP{$no} or die "$no not found";
    return $comiket->{$circle->day};
}


sub __get_area  {
    my($circle) = @_;
    my $area = Hirukara::Constants::Area::lookup($circle);
    $area =~ s/^(.+\d+).*?$/$1/;
    return $area;
}

sub run {
    my($self) = @_;
    my $csv = $self->csv;
    my $database = $self->database;
    my $member_id = $self->member_id;
    my $in_database = {};
    my $in_checklist = {};
    my $diff = {};

    local *Hirukara::Parser::CSV::Row::comiket_no = sub { $csv->comiket_no }; ## oops :-(

    for my $c (@{$csv->circles})  {
        ## remove rejected circle
        if (__get_day($c) eq "0")   {
            next;
        }

        my $circle = Hirukara::Command::Circle::Create->new(
            database      => $database,
            comiket_no    => $csv->comiket_no,
            circle_name   => $c->circle_name,
            circle_author => $c->circle_author,
            day           => __get_day($c),
            area          => __get_area($c),
            circle_sym    => $c->circle_sym,
            circle_num    => $c->circle_num,
            circle_flag   => $c->circle_flag ? "b" : "a",
            circlems      => $c->circlems,
            url           => $c->url,
        );

        my $md5 = $circle->id;
        my $in_db = $database->single('circle', { id => $md5 });

        if (!$in_db)   {
            debugf "CIRCLE_CREATE: name=%s, author=%s", $c->circle_name, $c->circle_author;
            $circle->run;
        }

        $in_checklist->{$md5} = { circle => $circle, favorite => $c };
        delete $circle->{database};
    }

    my $it = $database->search('checklist', { member_id => $member_id });

    while ( my $row = $it->next ) {
        $in_database->{$row->circle_id} = { favorite => $row->get_columns };
    }

    while ( my($md5,$data) = each %$in_checklist )  {
        if ($in_database->{$md5}) {
            $diff->{exist}->{$md5} = $data;
        } else {
            $diff->{create}->{$md5} = $data;
        }
    }

    while ( my($md5,$data) = each %$in_database )  {
        if (!$in_checklist->{$md5}) {
            my $circle = $database->single('circle', { id => $data->{favorite}->{circle_id} });
            $data->{circle} = $circle->get_columns;

            $diff->{delete}->{$md5} = $data;
        }
    }

    $self->merge_results($diff);
    $self->action_log([
        member_id  => $member_id,
        exhibition => $csv->comiket_no,
        checklist  => scalar keys %$in_checklist,
        database   => scalar keys %$in_database,
        exist  => scalar keys %{$diff->{exist}},
        create => scalar keys %{$diff->{create}},
        delete => scalar keys %{$diff->{delete}},
    ]);

    $self;
}


sub run_merge   {
    my($self) = @_;
    my $member_id = $self->member_id;
    my $diff = $self->merge_results;
    my $database = $self->database;

    while ( my($md5,$data) = each %{$diff->{create}})  {
        my $circle = $data->{circle};
        debugf "CREATE_FAVORITE: circle_name=%s, member_id=%s", map { encode_utf8 $_ } $circle->{circle_name}, $member_id;

        $database->insert('checklist', {
            circle_id => $md5,
            member_id => $member_id,
            comment   => $data->{favorite}->{comment},
            count     => 1,
        });
    }

    while ( my($md5,$data) = each %{$diff->{exist}})  {
        my $circle = $data->{circle};
        debugf "UPDATE_FAVORITE: circle_name=%s, member_id=%s", map { encode_utf8 $_ } $circle->{circle_name}, $member_id;
    }

    while ( my($md5,$data) = each %{$diff->{delete}})  {
        my $circle = $data->{circle};
        debugf "DELETE_FAVORITE: circle_name=%s, member_id=%s", map { encode_utf8 $_ } $circle->{circle_name}, $member_id;
    }

    return $diff;
}

1;
