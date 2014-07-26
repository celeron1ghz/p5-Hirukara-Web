package Hirukara::Excel;
use utf8;
use Mouse;
use File::Temp();
use Excel::Writer::XLSX;
use Hirukara::Util;

has file => ( is => 'ro', isa => 'File::Temp', default => sub { File::Temp->new } );

has checklists => ( is => 'rw', isa => 'ArrayRef' );

sub process {
    my($self,$checks) = @_;
    my $checks = $self->checklists;

    my $row = 3;
    my @cols = (
        {
            width  => 30,
            header => "サークル名",
            key    => "circle_name",
        },
        {
            width  => 30,
            header => "作者",
            key    => "circle_author",
        },
        {
            width  => 30,
            header => "スペース",
            key    => Hirukara::Util->can('get_circle_space')
        },
        {
            width  => 10,
            header => "冊数/人数",
            key    => sub {
                my($circle,$favorite) = @_;
                my $total = 0;
                $total += $_->count for @$favorite;
                sprintf "%s冊/%s人", $total, scalar @$favorite;
            },
        },
        {
            width  => 40,
            header => "コメント",
            key    => sub {
                my($circle,$favorite) = @_;
                my @ret;
                for my $f (@$favorite) {
                    my $val = sprintf "%s(%s)%s", $f->member_id, $f->count, $f->comment ? ":" . $f->comment : "";
                    if ($f->comment) { unshift @ret, $val }
                    else             { push @ret, $val }
                }
                return join "\n", @ret;
            },
        },
 
    );

    my $fh = $self->file;
    my $x = Excel::Writer::XLSX->new($fh->filename);

    my $s = $x->add_worksheet("moge");
    $s->set_portrait;
    $s->set_margins_TB(0.2);
    $s->set_margins_LR(0.3);

    my $header = $x->add_format();
    $header->set_bold;
    $header->set_border;
    $header->set_align("center");
    $header->set_bg_color($x->set_custom_color(34, "#cccccc"));

    my $body = $x->add_format();
    $body->set_border;
    $body->set_size(8);

    for ( my $i = 0; $i < @cols; $i++ ) {
        my $col = $cols[$i];
        $s->set_column($i, $i, $col->{width});
        $s->write(2, $i, $col->{header}, $header);
    }

    for my $data (@$checks) {
        my $circle = $data->{circle};
        my $favorite = $data->{favorite};


        for ( my $col = 0; $col < @cols; $col++ )   {
            my $ret = $cols[$col]->{key};
            my $val = ref $ret eq 'CODE' ? $ret->($circle,$favorite) : $circle->$ret;
            $s->write($row, $col, $val, $body);
        }

        $row++;
    }

    $x->close;
}

1;
