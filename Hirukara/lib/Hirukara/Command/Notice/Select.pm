package Hirukara::Command::Notice::Select;
use Moose;

with 'MooseX::Getopt', 'Hirukara::Command';

sub run {
    my $self = shift;
    my $time = time - 60 * 60 * 24 * 60;
    [ $self->hirukara->db->search('notice' => {
        created_at => \'= (SELECT MAX(created_at) FROM notice n WHERE notice.key = n.key)',
        key        => { '>=' => $time },  ## TODO: should change create_at to epoch value
    }, {
        order_by => "key DESC",
    })->all ];
}

1;
