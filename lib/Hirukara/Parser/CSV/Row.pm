package Hirukara::Parser::CSV::Row;
use Mouse;

sub csv_columns {
    (
        'type',         # 01
        'serial_no',    # 02
        'color',        # 03
        'page_no',      # 04
        'cut_index',    # 05
        'day',          # 06
        'area',         # 07
        'circle_sym',   # 08
        'circle_num',   # 09
        'genre',        # 10
        'circle_name',  # 11
        'circle_kana',  # 12
        'circle_author',# 13
        'publish_info', # 14
        'url',          # 15
        'mail',         # 16
        'remark',       # 17
        'comment',      # 18
        'map_x',        # 19
        'map_y',        # 20
        'map_layout',   # 21
        'circle_flag',  # 22
        'update_info',  # 23
        'circlems',     # 24
        'rss',          # 25
        'rss_info',     # 26
    );
}

has $_ => ( is => 'ro', isa => 'Str|Undef' ) for __PACKAGE__->csv_columns;

sub as_csv_column   {
    my $self = shift;
    join "," => map { $self->$_ } $self->csv_columns
}

1;
