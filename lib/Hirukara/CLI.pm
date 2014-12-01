package Hirukara::CLI;
use strict;
use Class::Load;
use Hirukara::Database;
use Text::UnicodeTable::Simple;

sub run {
    my $clazz = shift;
    my $type = shift or die;
    my $command_class = sprintf "Hirukara::Command::%s", join "::", map { ucfirst lc $_ } split '_', $type;
    Class::Load::load_class($command_class);

    my $conf = do 'config/development.pl';
    my $database = Hirukara::Database->load($conf->{database});
    my $obj = $command_class->new_with_options(database => $database);
    my $ret = $obj->run;
    my $t = Text::UnicodeTable::Simple->new;

    if ($ret and $ret->isa("Teng::Row"))   {
        my @headers = @{$ret->{table}->{columns}};

        $t->set_header(@headers);
        $t->add_row( map { $ret->$_ } @headers );
    
        print $t;
    } elsif ($ret and $ret->isa("Teng::Iterator")) {
        my @headers = @{$ret->{table}->{columns}};

        $t->set_header(@headers);

        while (my $r = $ret->next)  {
            $t->add_row( map { $r->$_ } @headers );
        }
    
        print $t;
 
    } else {
        print "exited. no value returned\n";
    }
}

1;
