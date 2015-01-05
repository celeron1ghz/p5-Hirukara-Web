package Hirukara::Command::Notice::Single;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

has key => ( is => 'ro', isa => 'Str', required => 1 );

sub run {
    my $self = shift;
    [ $self->database->search('notice' => {
        key => $self->key,
    }, {
        order_by => "created_at DESC",
    })->all ];
}

1;
