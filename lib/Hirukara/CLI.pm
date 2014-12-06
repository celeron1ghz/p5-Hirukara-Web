package Hirukara::CLI;
use Mouse;
use Class::Load;
use Hirukara::Database;
use Text::UnicodeTable::Simple;
use Module::Pluggable::Object;

sub get_all_command_object  {
    Module::Pluggable::Object->new(search_path => 'Hirukara::Command')->plugins;
}

sub to_command_name {
    my $val = shift or return;
    $val =~ s/^Hirukara::Command::// or return;
    return join '_', map { lc $_ } split '::', $val,
}

sub to_class_name   {
    my $val = shift or return;
    return join '::', 'Hirukara::Command', map { ucfirst lc $_ } split '_', $val;
}

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
    my $type = shift or return usage();
    my $command_class = sprintf "Hirukara::Command::%s", join "::", map { ucfirst lc $_ } split '_', $type;
    my($is_success,$error) = Class::Load::try_load_class($command_class);

    unless ($is_success)    {
        die "command '$type' load fail. Reason are below:\n----------\n$error\n----------\n";
    }

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
