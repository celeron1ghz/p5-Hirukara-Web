use strict;
use Teng::Schema::Loader;
use YAML;

my $conf    = do 'config/development.pl';
my $members = YAML::LoadFile('config/members.yaml');
my $db = Teng::Schema::Loader->load(%{ $conf->{Teng} });

for my $u ($db->search("member"))   {
    my $id =  $u->member_id;
    my $name = $members->{$id};

    if ($u->display_name ne $name)  {
        $u->display_name($name);
        $u->update;
        warn "updated $id --> $name";
    }
}
