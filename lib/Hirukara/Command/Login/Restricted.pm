package Hirukara::Command::Login::Restricted;
use utf8;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command', 'Hirukara::Command::Login';

sub run {
    my $self = shift;
    my $id   = $self->screen_name;
    my $mem  = $self->db->single(member => { member_id => $id })
        or Hirukara::DB::MemberNotInDatabaseException->throw(member_id => $id);

    $self->db->update($mem, { image_url => $self->profile_image_url_https });
    $self->actioninfo("ログインしました。", member_id => $id, serial => $self->id, name => $self->name);

    +{
        member_id         => $id,
        member_name       => $mem->member_name,
        profile_image_url => $self->profile_image_url_https,
    }
}

__PACKAGE__->meta->make_immutable;
