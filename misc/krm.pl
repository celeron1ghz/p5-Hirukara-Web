use strict;
use URI;
use Web::Scraper;
use YAML;

my $scraper = scraper {
    process "table tr", 'circles[]' => scraper {
        process "td:nth-child(2)",   'circle_space'  => 'TEXT';
        process "td:nth-child(3)",   'circle_name'   => 'TEXT';
        process "td:nth-child(4)",   'circle_author' => 'TEXT';
        process "td:nth-child(5) a", 'url'   => '@href';
        process "td:nth-child(6) a", 'pixiv' => '@href';
    };
};

my @circles;
for my $cnt (1,2)   {
    warn "fetching $cnt...";

    my $ret = $scraper->scrape(URI->new("http://koromu-toho.com/koromu10_list/list_koromu10.files/sheet00$cnt.htm"));
    push @circles, @{$ret->{circles}};
}

YAML::DumpFile("krm10.yaml", \@circles);
