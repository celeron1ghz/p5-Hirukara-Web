use strict;
use Web::Scraper;
use URI;
use YAML;

my $uri = URI->new("http://reitaisai.com/rts12/name-circle");
my $s   = scraper {
    process '.entry-content table tr', 'circles[]' => scraper {
        process 'td:nth-child(1)', 'circle_space'  => 'TEXT';
        process 'td:nth-child(2)', 'circle_name'   => 'TEXT';
        process 'td:nth-child(3)', 'circle_author' => 'TEXT';
    };
};

YAML::DumpFile 'rts11.yaml', $s->scrape($uri);
