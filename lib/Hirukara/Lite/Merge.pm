package Hirukara::Lite::Merge;
use strict;
use Digest::MD5 'md5_hex';
use Log::Minimal;
use Encode;

sub merge_checklist {
    my($class,$db,$csv,$member_id) = @_;
    my $in_database = {};
    my $in_checklist = {};
    my $diff = {};

    for my $c (@{$csv->circles})  {
        my $identifier = join "-", map { encode_utf8 $c->$_ } qw/circle_name circle_author/;
        my $md5 = md5_hex($identifier);

        my $circle = $db->single('circle', { id => $md5 });

        if (!$circle)   {
            #infof "Creating circle: name=%s, author=%s", $c->circle_name, $c->circle_author;

            my $ret = $db->insert('circle', {
                id            => $md5,
                comiket_no    => $csv->comiket_no,
                circle_name   => $c->circle_name,
                circle_author => $c->circle_author,
                day           => $c->day,
                area          => $c->area,
                circle_sym    => $c->circle_sym,
                circle_num    => $c->circle_num,
                circle_flag   => $c->circle_flag ? "b" : "a",
            });

            $circle = $ret->get_columns;
        }

        $in_checklist->{$md5} = { circle => $circle, favorite => $c };
    }

    my $it = $db->search('checklist', { member_id => $member_id });

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
            my $circle = $db->single('circle', { id => $data->{favorite}->{circle_id} });
            $data->{circle} = $circle->get_columns;

            $diff->{delete}->{$md5} = $data;
        }
    }

    infof "COUNTS: checklist=%s, database=%s, update=%s, create=%s, delete=%s"
        , scalar keys %$in_checklist
        , scalar keys %$in_database
        , scalar keys %{$diff->{exist}}
        , scalar keys %{$diff->{create}}
        , scalar keys %{$diff->{delete}};


    while ( my($md5,$data) = each %{$diff->{create}})  {
        infof "CREATE_FAVORITE: circle_name=%s, member_id=%s", map { encode_utf8 $_ } $data->{circle_name}, $member_id;

        $db->insert('checklist', {
            circle_id => $md5,
            member_id => $member_id,
            comment   => $data->{favorite}->{comment},
        });
    }

    while ( my($md5,$data) = each %{$diff->{exist}})  {
        infof "UPDATE_FAVORITE: circle_name=%s, member_id=%s", map { encode_utf8 $_ } $data->{circle_name}, $member_id;
    }

    while ( my($md5,$data) = each %{$diff->{delete}})  {
        infof "DELETE_FAVORITE: circle_name=%s, member_id=%s", map { encode_utf8 $_ } $data->{circle_name}, $member_id;
    }

    return $diff;
}

1;
