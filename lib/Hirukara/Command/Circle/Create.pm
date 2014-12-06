package Hirukara::Command::Circle::Create;
use Mouse;
use Encode;
use Digest::MD5 'md5_hex';

with 'MouseX::Getopt', 'Hirukara::Command';

my @COLUMNS = qw/
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
    serialized
/;

has $_ => ( is => 'ro', isa => 'Str', required => 1 ) for @COLUMNS;

sub id  {
    my $self = shift;
    my $val = join "-", map { encode_utf8 $self->$_ }
          "comiket_no"
        , "day"
        , "circle_sym"
        , "circle_num"
        , "circle_flag"
        , "circle_name";

    return md5_hex($val);
}

sub run {
    my $self = shift;
    my $circle = {
        id => $self->id,
        map { $_ => $self->$_ } @COLUMNS,
    };

    my $ret = $self->database->insert(circle => $circle);
    $ret;
}

1;
