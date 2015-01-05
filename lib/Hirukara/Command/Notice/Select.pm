package Hirukara::Command::Notice::Select;
use Mouse;

with 'MouseX::Getopt', 'Hirukara::Command';

sub run {
    my $self = shift;
    [ $self->database->search('notice' => {
        created_at => \'= (SELECT MAX(created_at) FROM notice n WHERE notice.key = n.key)'
    }, {
        order_by => "key DESC",
    })->all ];
}

1;
