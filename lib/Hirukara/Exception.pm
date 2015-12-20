package Hirukara::Exception;
use utf8;
use strict;
use warnings;
use parent 'Exception::Tiny';

## cli
package Hirukara::CLI::ClassLoadFailException {
    use parent -norequire, 'Hirukara::Exception';
}

## csv
package Hirukara::CSV::FileIsEmptyException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::CSV::HeaderNumberIsWrongException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::CSV::InvalidHeaderException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::CSV::UnknownCharacterEncodingException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::CSV::NotAComiketException {
    use parent -norequire, 'Hirukara::Exception';

    sub message { "現在受け付けているのはコミケットではないのでチェックリストをアップロードできません。" }
}

package Hirukara::CSV::ExhibitionNotMatchException {
    use parent -norequire, 'Hirukara::Exception';
    use Class::Accessor::Lite ro => ['want_exhibition', 'given_exhibition'];

    sub message {
        my $self = shift;
        sprintf "アップロードされたCSVファイルは'%s'のCSVですが、現在受け付けているのは'%s'のCSVです。", $self->given_exhibition, $self->want_exhibition; 
    }
}

## circle
package Hirukara::Circle::CircleNotFoundException {
    use parent -norequire, 'Hirukara::Exception';
}

## checklist
package Hirukara::Checklist::InvalidExportTypeException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::Checklist::NotAComiketException {
    use parent -norequire, 'Hirukara::Exception';
}

## assign list
package Hirukara::AssignList::AssignExistException {
    use parent -norequire, 'Hirukara::Exception';
}

## general
package Hirukara::DB::NoSuchRecordException {
    use parent -norequire, 'Hirukara::Exception';
}

package Hirukara::DB::RelatedRecordNotFoundException {
    use parent -norequire, 'Hirukara::Exception';
}

1;
