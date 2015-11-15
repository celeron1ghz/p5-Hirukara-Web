requires 'Amon2', '6.12';
requires 'Crypt::CBC';
requires 'Crypt::Rijndael';
requires 'DBD::SQLite', '1.33';
requires 'HTML::FillInForm::Lite', '1.11';
requires 'HTTP::Session2', '1.03';
requires 'JSON', '2.50';
requires 'Module::Functions', '2';
requires 'Plack::Middleware::ReverseProxy', '0.09';
requires 'Router::Boom', '0.06';
requires 'Starlet', '0.20';
requires 'Teng', '0.18';
requires 'Test::WWW::Mechanize::PSGI';
requires 'Text::Xslate', '2.0009';
requires 'Time::Piece', '1.20';
requires 'perl', '5.010_001';

requires 'Amon2::Plugin::Web::Auth';
requires 'Moose';
requires 'MooseX::Getopt';
requires 'String::CamelCase';
requires 'Text::CSV';
requires 'Teng::Plugin::SearchJoined';
requires 'Exception::Tiny';
requires 'Module::Pluggable::Object';
requires 'Log::Minimal';
requires 'Net::OAuth';
requires 'Net::Twitter::Lite';
requires 'WebService::Slack::WebApi';
requires 'Lingua::JA::Regular::Unicode';
requires 'Archive::Zip';
requires 'Parallel::ForkManager';
requires 'Cache::Memcached::Fast';
requires 'Proclet';

requires 'LWP::Protocol::PSGI';
requires 'Text::SimpleTable';
requires 'Test::Time::At';
requires 'Test::AllModules';
requires 'Test::Mock::Guard';

on configure => sub {
    requires 'Module::Build', '0.38';
    requires 'Module::CPANfile', '0.9010';
};

on test => sub {
    requires 'Test::More', '0.98';
};
