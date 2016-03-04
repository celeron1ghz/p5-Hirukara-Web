+{
    "Auth" => {
        "Twitter" => {
            "consumer_key"    => ($ENV{HIRUKARA_TWITTER_CONSUMER_KEY}    or die "env HIRUKARA_TWITTER_CONSUMER_KEY is not set"),
            "consumer_secret" => ($ENV{HIRUKARA_TWITTER_CONSUMER_SECRET} or die "env HIRUKARA_TWITTER_CONSUMER_SECRET is not set"),
            "ssl"             =>  1,  
        },  
    }, 
};
