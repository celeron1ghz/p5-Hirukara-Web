package Hirukara::Export::Excel;
use utf8;
use Mouse;
use File::Temp();
use Excel::Writer::XLSX;

with 'Hirukara::Export';

sub get_extension { "xlsx" }

sub process {
    my($self) = @_;
    my $checks = $self->checklists;
    my $cnt = 0;

    my @cols = (
        { width  => 2, header => "#", key => sub { ++$cnt } },
        {
            width  => 3,
            header => "No",
            key => sub {
                my $c = shift;
                my $val = $c->comiket_no;
                $val =~ s/ComicMarket/C/;
                $val;
            },
        },
        {
            width  => 5,
            header => "曜日",
            key => sub {
                my $c = shift;
                sprintf "%s日目", $c->day;
            }
        },
        { width  => 7, header => "地区", key => "area" },
        {
            width  => 8,
            header => "スペース",
            key => sub {
                my $c = shift;
                join "", map { $c->$_ } qw/circle_sym circle_num circle_flag/
            }
        },
        { width  => 30, header => "サークル名", key => "circle_name"    },
        { width  => 30, header => "作者",       key => "circle_author"  },
        {
            width  => 7,
            header => "冊数",
            key    => sub {
                my($circle,$favorite) = @_;
                my $total = 0;
                $total += $_->count for @$favorite;
                sprintf "%s冊", $total;
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
    my $x  = Excel::Writer::XLSX->new($fh->filename);
    my %assigns;

    ## assign selecting
    for my $data (@$checks) {
        my $assign = $data->{assign};

        for my $a (@$assign)    {
            $assigns{$a->id}->{assign} = $a;
            push @{$assigns{$a->id}->{rows}}, $data;
        }
    }

    ## output
    my @sorted = sort keys %assigns;

    for my $id (@sorted)  {
        my $row    = 3;
        my $data   = $assigns{$id};
        my $rows   = $data->{rows};
        my $assign = $data->{assign};
        my $s      = $x->add_worksheet(sprintf "(%s) %s", $assign->id, $assign->name);
        $cnt = 0;

        for my $data (@$rows)    {
            $s->set_portrait;
            $s->set_margins_TB(0.2);
            $s->set_margins_LR(0.3);

            my $header = $x->add_format();
            $header->set_bold;
            $header->set_border;
            $header->set_align("center");
            #$header->set_bg_color($x->set_custom_color(34, "#cccccc"));

            my $body = $x->add_format();
            $body->set_border;
            $body->set_size(8);

            for ( my $i = 0; $i < @cols; $i++ ) {
                my $col = $cols[$i];
                $s->set_column($i, $i, $col->{width});
                $s->write(2, $i, $col->{header}, $header);
            }

            my $circle   = $data->{circle};
            my $favorite = $data->{favorite};
            my $assign   = $data->{assign};

            for ( my $col = 0; $col < @cols; $col++ )   {
                my $ret = $cols[$col]->{key};
                my $val = ref $ret eq 'CODE' ? $ret->($circle,$favorite) : $circle->$ret;
                $s->write($row, $col, $val, $body);
            }

            $row++;
        }
    }

    $x->close;
    $self->file;
}

1;
