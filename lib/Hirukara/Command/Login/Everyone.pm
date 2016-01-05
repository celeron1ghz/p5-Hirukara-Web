package Hirukara::Command::Login::Everyone;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Login';

sub run {
    my $self   = shift;
    my $serial = $self->id;
    my $id     = $self->screen_name;
    my $name   = $self->name;
    my $image  = $self->profile_image_url_https;

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

    $self->actioninfo("ログインしました。", member_id => $id, serial => $serial, name => $name);

    +{
        member_id         => $id,
        member_name       => $mem->member_name,
        profile_image_url => $image,
    }
}

__PACKAGE__->meta->make_immutable;
