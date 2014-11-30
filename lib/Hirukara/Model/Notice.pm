package Hirukara::Model::Notice;
use utf8;
use Mouse;
use Smart::Args;
use Log::Minimal;

with 'Hirukara::Model';

sub get_notice  {
    my $self = shift;
    $self->database->single('notice' => { id => \'= (SELECT MAX(id) FROM notice)' });
}

sub update_notice   {
    args my $self,
         my $member_id => { isa => 'Str' },
         my $text      => { isa => 'Str' };

    infof "UPDATE_NOTICE: member_id=%s", $member_id;
    $self->database->insert(notice => {
        member_id => $member_id,
        text      => $text,
    }); 
}

1;
