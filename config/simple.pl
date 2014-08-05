use HTTP::Session::Store::Memcached;
use Cache::Memcached::Fast;

{
    "Teng" => {
        connect_info => ["", "", "", { sqlite_unicode => 1 }], 
        namespace => '',
    },  

    "Auth" => {
        "Twitter" => {
            "consumer_key"    => '',
            "consumer_secret" => '',
            "ssl"             =>  1,  
        },  
    }, 

    'Text::Xslate' => { cache => 0 },

    'Hirukara::Auth' => {
        admin => [],
    },

    "Session" => {
        store => HTTP::Session::Store::Memcached->new(
            memd => Cache::Memcached::Fast->new({ servers => ['127.0.0.1:11211'] }),
        ),
    },
}
