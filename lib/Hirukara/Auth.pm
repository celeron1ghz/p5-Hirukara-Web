package Hirukara::Auth;
use Mouse;
use Smart::Args;
use Log::Minimal;

has roles => ( is => 'ro', isa => 'HashRef', required => 1 );

sub BUILD   {
    my $self = shift;
    my $roles = $self->roles;

    while ( my($role,$members) = each %$roles)   {
        $self->{__roles}->{$role} = { map { $_ => 1 } @$members };
    }
}

sub has_role    {
    args my $self,
         my $member_id => { isa => 'Str' },
         my $role      => { isa => 'Str' };

    my $ret = $self->{__roles}->{$role}->{$member_id};
    
    if ($ret) { infof "AUTH_SUCCESS: member_id=%s, role=%s", $member_id, $role  }
    else      { infof "AUTH_FAILTURE: member_id=%s, role=%s", $member_id, $role }

    return $ret;
}

1;
