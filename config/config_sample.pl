use HTTP::Session::Store::Memcached;
use Cache::Memcached::Fast;

{
    "hirukara" => {
        exhibition => "ComicMarket87",
    },

    "database" => {
        connect_info => ["dbi:SQLite:sample.db", "", "", { sqlite_unicode => 1 }], 
        namespace => 'Hirukara::Lite::Database',
    },  

    "Auth" => {
        "Twitter" => {
            "consumer_key"    => 'your consumer key',
            "consumer_secret" => 'your secret key',
            "ssl"             =>  1,  
        },  
    }, 

    #'Text::Xslate' => { cache => 0 },

    "Session" => {
        store => HTTP::Session::Store::Memcached->new(
            memd => Cache::Memcached::Fast->new({ servers => ['127.0.0.1:11211'] }),
        ),
    },
}
