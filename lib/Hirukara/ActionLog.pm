package Hirukara::ActionLog;
use strict;
use utf8;
use JSON;
use Carp;

my %LOGS = ( 
    CHECKLIST_CREATE => {
        type    => 'チェックの追加',
        message => q/'$member_id' さんが '$circle_name' を追加しました/,
    },

    CHECKLIST_DELETE => {
        type    => 'チェックの削除',
        message => q/'$member_id' さんが '$circle_name' を削除しました/,
    },

    CHECKLIST_MERGE => {
        type    => 'チェックリストのアップロード',
        message => q/'$member_id' さんが $comiket_no のチェックリストをアップロードしました。(追加=$create,削除=$delete,重複=$exist)/,
    },
);

sub extract_log {
    my($clazz,$log) = @_;
    $log or croak "log object not specified";

    my $id = $log->message_id;
    my $data = $LOGS{$id} or die "unknown message id '$id'";

    my $mess = $data->{message};
    my $param = decode_json $log->parameters;

    $mess =~ s/\$(\w+)/$param->{$1}/eg;
    +{ message => $mess, type => $data->{type} };
}

1;
