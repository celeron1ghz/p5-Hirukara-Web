use strict;
use Teng::Schema::Loader;
use Hirukara::Util;
use Encode;

my $conf = do "config/development.pl";
my $db = Teng::Schema::Loader->load($conf->{Teng});

my @records = $db->search_by_sql(<<SQL)->all;
SELECT circle.* FROM circle
    WHERE circle_name IN
        ( SELECT circle_name FROM circle GROUP BY circle_name HAVING COUNT(circle_name) > 1 )
    ORDER BY circle_name, circle_sym;
SQL

warn "!!!!!!!!!!!!!!!!!!", scalar @records;

while ( my($padd,$non_padd) = splice @records, 0, 2 ) {
    my $padd_str     = Hirukara::Util::get_circle_space($padd);
    my $non_padd_str = Hirukara::Util::get_circle_space($non_padd);

    warn "-----------------------------------------";

    unless ($padd_str eq $non_padd_str) {
        warn encode_utf8 sprintf "space seems to not match. skipping: circle_name is %s, space is %s and %s", $padd->circle_name, $padd_str, $non_padd_str;
        next;
    }

    unless ($padd->circle_name eq $non_padd->circle_name)    {
        warn encode_utf8 sprintf "circle name not match. circle_name is %s and %s", $padd->circle_name, $non_padd->circle_name;
        next;
    }

    unless ($padd->circle_author eq $non_padd->circle_author)    {
        warn encode_utf8 sprintf "circle author not match. circle_author is %s and %s", $padd->circle_author, $non_padd->circle_author;
        next;
    }

    #warn $non_padd->comment if $non_padd->comment;
    #warn $padd->comment if $padd->comment;


    my @non_padd_checks = $db->search(checklist => { circle_id => $non_padd->id })->all;

    for my $c (@non_padd_checks) {
        warn encode_utf8 sprintf "update favorite data: circle_name=%s, member=%s", $padd->circle_name, $c->member_id;

        $c->circle_id($padd->id);
        $c->update;
    }

    $non_padd->circle_type(99); ## deprecation mark
    $non_padd->update;
}
