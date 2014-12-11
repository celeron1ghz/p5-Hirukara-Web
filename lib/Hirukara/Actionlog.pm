package Hirukara::Actionlog;
use utf8;
use Mouse;
use Smart::Args;
use Log::Minimal;
use Carp;
use JSON;

my %LOGS = ( 
    CHECKLIST_CREATE => {
        type    => 'チェックの追加',
        message => q/$member_id さんが '$circle_name' を追加しました/,
    },

    CHECKLIST_DELETE => {
        type    => 'チェックの削除',
        message => q/$member_id さんが '$circle_name' を削除しました/,
    },

    CHECKLIST_DELETE_ALL => {
        type    => 'チェックの全削除',
        message => q/$member_id さんが全てのチェックを削除しました。(削除数=$count)/,
    },

    CHECKLIST_MERGE => {
        type    => 'チェックリストのアップロード',
        message => q/$member_id さんが $comiket_no のチェックリストをアップロードしました。(追加=$create,削除=$delete,重複=$exist)/,
    },

    CHECKLIST_ORDER_COUNT_UPDATE => {
        type    => 'チェックリスト情報の更新',
        message => q/$member_id さんが '$circle_name' のチェックリストの情報を変更しました。(変更前=$before_cnt,変更後=$after_cnt,コメントの変更=$comment_changed)/,
    },

    MEMBER_CREATE => {
        type    => 'メンバーの新規ログイン',
        message => q/$member_id さんが初めてログインしました/,
    },

    CIRCLE_TYPE_UPDATE => {
        type    => 'サークルの属性変更',
        message => q/$member_id さんが '$circle_name' の属性を変更しました。(変更前=$before_type,変更後=$after_type)/,
    },

    CIRCLE_COMMENT_UPDATE => {
        type    => 'サークルのコメント変更',
        message => q/$member_id さんが '$circle_name' のコメントを変更しました。/,
    },


    ASSIGN_MEMBER_UPDATE => {
        type    => '割り当て担当の変更',
        message => q/$updated_by さんが割り当てID $assign_id の割り当て担当を変更しました。(変更前=$before_member,変更後=$updated_member)/,
    },

    ASSIGN_NAME_UPDATE => {
        type    => '割り当て名の変更',
        message => q/$updated_by さんが割り当てID $assign_id の名前を変更しました。(変更前=$before_name,変更後=$updated_name)/,
    },
);

sub get {
    my($class,$key) = @_;
    $LOGS{$key};
}

sub extract_log {
    my($clazz,$log) = @_;
    $log or croak "log object not specified";

    my $id = $log->message_id;
    my $data = $LOGS{$id} or die "unknown message id '$id'";

    my $mess = $data->{message};
    my $param = decode_json $log->parameters;

    $mess =~ s/\$(\w+)/$param->{$1} || ''/eg;
    +{ message => $mess, type => $data->{type} };
}

1;
