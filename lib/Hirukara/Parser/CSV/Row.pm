package Hirukara::Parser::CSV::Row;
use Mouse;

has $_ => ( is => 'ro', isa => 'Str' ) for qw/color comment circle_name circle_author week area day circle_sym circle_num circle_flag remark/;

1;
