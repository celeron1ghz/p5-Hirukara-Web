package Hirukara::Exception;
use strict;
use warnings;
use parent 'Exception::Tiny';

package Hirukara::CSV::Header::HeaderNumberIsWrongException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::CSV::Header::InvalidHeaderException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::CSV::Header::UnknownCharacterEncodingException {
    use parent -norequire, 'Hirukara::Exception';
}

1;
