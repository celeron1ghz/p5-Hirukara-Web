package Hirukara::Command::CircleType::Create;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has type_name => ( is => 'ro', isa => 'Str', required => 1 );
has scheme    => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    my $ret  = $self->hirukara->db->insert(circle_type => {
        type_name  => $self->type_name,
        scheme     => $self->scheme,
        created_at => time,
    });

    $self->hirukara->actioninfo(undef, "サークルの属性を追加しました。" => name => $self->type_name, scheme => $self->scheme);
    $ret;
}

1;
