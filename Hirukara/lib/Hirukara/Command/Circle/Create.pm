package Hirukara::Command::Circle::Create;
use utf8;
use Moose;
use JSON;
use Encode;
use Digest::MD5 'md5_hex';

with 'MooseX::Getopt', 'Hirukara::Command';

my @REQUIRE_COLUMNS = qw/
    comiket_no
    circle_name
    circle_author
    day
    area
    circle_sym
    circle_num
    circle_flag
    circlems
    url
/;

my @OPTIONAL_COLUMNS = (
    'type',         # 01
    'serial_no',    # 02
    'color',        # 03
    'page_no',      # 04
    'cut_index',    # 05
    'genre',        # 10
    'circle_kana',  # 12
    'publish_info', # 14
    'mail',         # 16
    'remark',       # 17
    'comment',      # 18
    'map_x',        # 19
    'map_y',        # 20
    'map_layout',   # 21
    'update_info',  # 23
    'circlems',     # 24
    'rss',          # 25
    'rss_info',     # 26
);

has $_ => ( is => 'ro', isa => 'Str', required => 1 ) for @REQUIRE_COLUMNS;
has $_ => ( is => 'ro', isa => 'Str' ) for @OPTIONAL_COLUMNS;

sub id  {
    my $self = shift;
    my $val = join "-", map { encode_utf8($self->$_ || '') }
          "comiket_no"
        , "day"
        , "circle_sym"
        , "circle_num"
        , "circle_flag"
        , "circle_name";

    return md5_hex($val);
}

sub serialized  {
    my $self = shift;
    encode_json { map { $_ => $self->$_ } @REQUIRE_COLUMNS, @OPTIONAL_COLUMNS, }
}

sub run {
    my $self = shift;
    my $circle = {
        id         => $self->id,
        serialized => $self->serialized,
        map { $_ => $self->$_ } @REQUIRE_COLUMNS, 
    };

    my $ret = $self->db->insert(circle => $circle);
    $self->actioninfo("サークルを作成しました。" => circle => $ret);
    $ret;
}

1;
