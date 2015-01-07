## util
requires "File::Slurp";
requires "Text::CSV";
requires "HTTP::Session";
requires "Smart::Args";
requires "Capture::Tiny";
requires "Log::Minimal";
requires "Lingua::JA::Regular::Unicode";
requires "Tie::IxHash";

## xs
requires "HTTP::Parser::XS";
requires "JSON::XS";

## twitter
requires "Net::OAuth";
requires "Net::Twitter::Lite";

## test
requires "Test::WWW::Mechanize::PSGI";
requires "Test::Perl::Critic";

## cli
requires "MouseX::Getopt";
requires "Text::UnicodeTable::Simple";
requires "Module::Pluggable";

## database
requires "Teng";
requires "Teng::Plugin::SearchJoined";
requires "DBD::SQLite";
requires "Cache::Memcached::Fast";

## web framework
requires "Amon2";
requires "Amon2::Lite";
requires "Amon2::Auth";
requires "Amon2::Plugin::Web::FillInFormLite";
requires "Amon2::Plugin::Web::HTTPSession";
requires "Teng";
requires "Teng::Schema::Loader";

## plack
requires "Plack";
requires "Starlet";
