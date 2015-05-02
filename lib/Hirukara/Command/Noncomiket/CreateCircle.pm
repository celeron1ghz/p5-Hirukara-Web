package Hirukara::Command::Noncomiket::Createcircle;
use Moose;
use YAML;
use Hirukara::Command::Circle::Create;
use Lingua::JA::Regular::Unicode;
use Log::Minimal;

with 'MooseX::Getopt', 'Hirukara::Command';

has exhibition => ( is => 'ro', isa => 'Str', required => 1 );
has filename   => ( is => 'ro', isa => 'Str', required => 1 );

## TODO: below hash is copied from Hirukara::Scraper::CSV. gather into one.
my %FILE_FILTER = ( 
    circle_sym => sub {
        my $val = shift;
        alnum_h2z($val);
    },  
    circle_num  => sub {
        my $val = shift;
        sprintf "%02s", $val;
    },  
);

sub run {
    my $self = shift;
    my $exhibition = $self->exhibition;
    my $filename   = $self->filename;

    -e $filename or die "$filename: No such file or directory";
    my $data = YAML::LoadFile($filename);
    infof "NONCOMIKET_BUKLINSERT_INIT: exhibition=%s, filename=%s", $exhibition, $filename;

    my $db   = $self->database;
    my $txn  = $db->txn_scope;
    my $cnt  = 0;

    for my $c ( @{$data->{circles}} )  {
        unless (keys %$c == 3)  {
            warn "given circle info is not enough, ignore...\n", YAML::Dump($c);
            next;
        }

        my($sym,$num,$flg) = $c->{circle_space} =~ /^(.*?)(\d+)([ab]{1,2})$/ or die "error circle_space string: $c->{circle_space}";

        my $args = {
            circle_name   => $c->{circle_name},
            circle_author => $c->{circle_author},
            day           => 1,
            comiket_no    => $exhibition,
            circle_sym    => $FILE_FILTER{circle_sym}->($sym),
            circle_num    => $FILE_FILTER{circle_num}->($num),
            circle_flag   => $flg,
            area          => '',
            url           => '',
            circlems      => '',
        };

        my $o = eval { Hirukara::Command::Circle::Create->new(%$args, database => $db)->run };
        if (my $error = $@) {
            my $dumped = YAML::Dump($args);

            die <<EOT;
error on insert circle:
================================================================================
$dumped
================================================================================

reason are below:
================================================================================
$error
================================================================================
EOT
        }

        $cnt++;
    }

    infof "NONCOMIKET_BUKLINSERT_CREATE: exhibition=%s, cnt=%s", $exhibition, $cnt;
    $txn->commit;
}

1;
