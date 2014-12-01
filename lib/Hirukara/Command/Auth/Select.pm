package Hirukara::Command::Auth::Select;
use Mouse;
use Log::Minimal;

with 'MouseX::Getopt', 'Hirukara::Command';

has member_id => ( is => 'ro', isa => 'Str', required => 1 );
has role_type => ( is => 'ro', isa => 'Str' );

sub run {
    my $self = shift;
    my $cond = { member_id => $self->member_id };
    $cond->{role_type} = $self->role_type if $self->role_type;

    $self->database->search(member_role => $cond);
}

1;


