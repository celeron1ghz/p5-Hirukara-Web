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

    CHECKLIST_ORDER_COUNT_UPDATE => {
        type    => 'チェックリスト情報の更新',
        message => q/'$member_id' さんが '$circle_name' のチェックリストの情報を変更しました。(変更前=$before_cnt,変更後=$after_cnt,コメントの変更=$comment_changed)/,
    },

    MEMBER_CREATE => {
        type    => 'メンバーの新規ログイン',
        message => q/'$member_name' さんが初めてログインしました/,
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
