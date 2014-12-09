use strict;
use Test::More tests => 2;
use Hirukara;

my $db = bless {}, 'Hirukara::Database'; ## just fake

subtest "no exhibition return on Hirukara.exhibition is empty" => sub {
    my $h  = Hirukara->new(database => $db);

    is $h->exhibition, undef, "exhibition is empty";
    is_deeply $h->get_context_args, {}, "context args is empty";
};


subtest "exhibition return on Hirukara.exhibition is exist" => sub {
    my $h = Hirukara->new(database => $db, exhibition => "mogemoge");

    is $h->exhibition, "mogemoge", "exhibition ok";
    is_deeply $h->get_context_args, { exhibition => 'mogemoge' }, "context args ok";
};
