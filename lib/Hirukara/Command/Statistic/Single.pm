package Hirukara::Command::Statistic::Single;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has member_id  => ( is => 'rw', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $data = $self->db->single_by_sql(<<"    SQL", [ $self->hirukara->exhibition, $self->member_id ]);
        SELECT
            *,
            all_count - circle_no_comment_count AS circle_commented_count,
            CAST(ROUND(all_count - circle_no_comment_count) / all_count * 100 AS INT)    AS circle_commented_percentage,

            all_count - checklist_no_comment_count AS checklist_commented_count,
            CAST(ROUND(all_count - checklist_no_comment_count) / all_count * 100 AS INT) AS checklist_commented_percentage
        FROM (
            SELECT
                COUNT(*) AS all_count,
                COUNT(CASE WHEN circle.day = 1 THEN 1 ELSE NULL END) AS day1_count,
                COUNT(CASE WHEN circle.day = 2 THEN 1 ELSE NULL END) AS day2_count,
                COUNT(CASE WHEN circle.day = 3 THEN 1 ELSE NULL END) AS day3_count,
                COUNT(CASE WHEN circle.comment    IS NULL OR circle.comment = ''    THEN 1 ELSE NULL END) AS circle_no_comment_count,
                COUNT(CASE WHEN checklist.comment IS NULL OR checklist.comment = '' THEN 1 ELSE NULL END) AS checklist_no_comment_count
            FROM circle
            LEFT JOIN checklist
                ON circle.id = checklist.circle_id
                WHERE circle.comiket_no = ?
                AND   checklist.member_id = ?
        )
    SQL

    $data;
}

1;
