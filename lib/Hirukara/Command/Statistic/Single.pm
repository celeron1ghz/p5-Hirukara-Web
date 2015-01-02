package Hirukara::Command::Statistic::Single;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has member_id  => ( is => 'rw', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $data = $self->database->single_by_sql(<<"    SQL", [ $self->exhibition, $self->member_id ]);
        SELECT
            COUNT(*) AS all_count,
            COUNT(CASE WHEN circle.day = 1 THEN 1 ELSE NULL END) AS day1_count,
            COUNT(CASE WHEN circle.day = 2 THEN 1 ELSE NULL END) AS day2_count,
            COUNT(CASE WHEN circle.day = 3 THEN 1 ELSE NULL END) AS day3_count
        FROM circle
        LEFT JOIN checklist
            ON circle.id = checklist.circle_id
            WHERE circle.comiket_no = ?
            AND   checklist.member_id = ?
    SQL

    $data;
}

1;
