package Hirukara::Model;
use Mouse::Role;
use JSON();

has database => ( is => 'ro', isa => 'Hirukara::Database', required => 1 );

around BUILDARGS => sub {
    my($orig,$class,@args) = @_;
    my $amon = $args[1];
    return $class->$orig(database => $amon->db);
};

sub __create_action_log   {
    my($self,$messid,$param) = @_;
    my $circle_id = $param->{circle_id};

    $self->database->insert(action_log => {
        message_id  => $messid,
        circle_id   => $circle_id,
        parameters  => JSON::encode_json $param,
    });
}

1;
