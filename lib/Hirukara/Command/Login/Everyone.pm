package Hirukara::Command::Login::Everyone;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

has id                      => ( is => 'ro', isa => 'Str', required => 1 );
has name                    => ( is => 'ro', isa => 'Str', required => 1 );
has screen_name             => ( is => 'ro', isa => 'Str', required => 1 );
has profile_image_url_https => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self   = shift;
    my $serial = $self->id;
    my $id     = $self->screen_name;
    my $name   = $self->name;
    my $image  = $self->profile_image_url_https;
    $self->actioninfo("ログインしました。", member_id => $id, serial => $serial, name => $name, image => $image);

    my $mem = $self->db->single(member => { member_id => $id });

    if ($mem)   {
        $self->db->update($mem, { image_url => $image });
    } else {
        $mem = $self->db->insert_and_fetch_row(member => {
            id          => $serial,
            member_id   => $id,
            member_name => $name,
            image_url   => $image,
            created_at  => time,
        });
    }

    +{
        member_id         => $id,
        member_name       => $mem->member_name,
        profile_image_url => $image,
    }
}

__PACKAGE__->meta->make_immutable;
