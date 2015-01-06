## util
requires "File::Slurp";
requires "Text::CSV";
requires "HTTP::Session";
requires "Excel::Writer::XLSX";
requires "Smart::Args";
requires "Capture::Tiny";
requires "Log::Minimal";
requires "Net::Twitter::Lite";
requires "Net::OAuth";
requires "Lingua::JA::Regular::Unicode";
requires "Tie::IxHash";

## test
requires "Test::WWW::Mechanize::PSGI";

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
