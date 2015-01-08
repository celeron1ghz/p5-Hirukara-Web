package Hirukara::CLI;
use strict;
use warnings;
use Hirukara;
use Text::UnicodeTable::Simple;

sub usage   {
    print <<EOT;
Usage: $0 <sub_command> [sub_command args...]

Sub commands are below:
EOT

    print join "\n", map { "    * $_" } map { to_command_name($_) } __PACKAGE__->get_all_command_object;
    print "\n";

    1; ## system exit code
}

sub run {
    my $clazz = shift;
    my $type  = shift or return usage();

    my $hirukara = Hirukara->load(do 'config/development.pl');
    my $ret   = $hirukara->run_command_with_options($type);

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
