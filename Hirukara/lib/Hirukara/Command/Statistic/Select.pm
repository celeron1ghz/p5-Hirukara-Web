package Hirukara::Command::Statistic::Select;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Exhibition';

has scores  => ( is => 'rw', isa => 'HashRef' );
has counts  => ( is => 'rw', isa => 'HashRef' );
has members => ( is => 'rw', isa => 'ArrayRef' );

sub run {
    my $self = shift;
    $self->scores($self->get_score);
    $self->counts($self->get_counts);
    $self->members([$self->get_members]);
    $self;
}

sub get_score   {
    my $self = shift;
    my $it = $self->database->search_by_sql(<<"    SQL", [ $self->exhibition ]);
        SELECT
            circle.day,
            circle.circle_sym,
            circle.circle_num,
            circle.circle_type,
            checklist.member_id
        FROM circle
        JOIN checklist ON circle.id = checklist.circle_id
        AND  circle.comiket_no = ?
    SQL

    my $scores = {};
    my $point = Hirukara::Database::Row::Circle->can('circle_point');

    for my $s ($it->all)    {   
        my $score = $point->($s);
        $scores->{$s->member_id} += $score;
    } 

    $scores;
}

sub get_counts  {
    my $self = shift;
    my $counts = $self->database->single_by_sql(<<"    SQL", [ $self->exhibition ]);
        SELECT
            COUNT(*) AS total_count,
            COUNT(CASE WHEN circle.day = 1 THEN 1 ELSE NULL END) AS day1_count,
            COUNT(CASE WHEN circle.day = 2 THEN 1 ELSE NULL END) AS day2_count,
            COUNT(CASE WHEN circle.day = 3 THEN 1 ELSE NULL END) AS day3_count
        FROM checklist 
            LEFT JOIN circle
                ON circle.id = checklist.circle_id
        WHERE circle.comiket_no = ?
    SQL

    $counts->get_columns;
}

sub get_members {
    my $self = shift;
    my $it = $self->database->search_by_sql(<<"    SQL", [ $self->exhibition ]);
        SELECT
            member.*,
            COUNT(checklist.member_id) AS total_count,
            COUNT(CASE WHEN circle.day = 1 THEN 1 ELSE NULL END) AS day1_count,
            COUNT(CASE WHEN circle.day = 2 THEN 1 ELSE NULL END) AS day2_count,
            COUNT(CASE WHEN circle.day = 3 THEN 1 ELSE NULL END) AS day3_count
        FROM member
            LEFT JOIN checklist ON member.member_id = checklist.member_id
            LEFT JOIN circle    ON circle.id = checklist.circle_id
        WHERE circle.comiket_no = ?
        GROUP BY member.member_id
        ORDER BY total_count DESC
    SQL

    [$it->all];
}

1;
