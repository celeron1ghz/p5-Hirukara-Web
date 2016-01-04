package Hirukara::Command::CircleType::Create;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has type_name => ( is => 'ro', isa => 'Str', required => 1 );
has scheme    => ( is => 'ro', isa => 'Str', required => 1 );
has run_by    => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret  = $self->db->insert_and_fetch_row(circle_type => {
        type_name  => $self->type_name,
        scheme     => $self->scheme,
        created_at => time,
    });

    $self->actioninfo("サークル属性を追加しました。" =>
        id => $ret->id, name => $self->type_name, scheme => $self->scheme, run_by => $self->run_by);
    $ret;
}

__PACKAGE__->meta->make_immutable;
