## util
requires "Text::CSV";
requires "HTTP::Session";
requires "Excel::Writer::XLSX";
requires "Smart::Args";
requires "Capture::Tiny";
requires "Text::Markdown";

## database
requires "Teng";
requires "Teng::Plugin::SearchJoined";
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
