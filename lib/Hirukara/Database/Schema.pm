package Hirukara::Database::Schema;
use 5.014002;

use DBIx::Schema::DSL;
use Aniki::Schema::Relationship::Declare;

database 'SQLite';

create_table 'member' => columns {
    varchar 'id',           primary_key;
    varchar 'member_id',    not_null, unique;
    varchar 'member_name',  not_null;
    varchar 'image_url',    not_null;
    integer 'created_at',   not_null;
};

create_table 'member_role' => columns {
    integer 'id',           primary_key, auto_increment;
    varchar 'member_id',    not_null;
    varchar 'role_type',    not_null;
    integer 'created_at',   not_null;

    belongs_to 'member';

    add_unique_index 'member_role_unique' => ['member_id', 'role_type'];
};

create_table 'checklist' => columns {
    integer 'id',           primary_key, auto_increment;
    varchar 'circle_id',    not_null;
    varchar 'member_id',    not_null;
    integer 'count',        not_null;
    varchar 'comment';
    integer 'created_at',   not_null;

    belongs_to 'circle';
    belongs_to 'member', foreign_column => 'member_id';

    add_unique_index 'checklist_unique' => ['circle_id', 'member_id'];
};

create_table 'circle' => columns {
    varchar 'id',           primary_key;
    varchar 'comiket_no',   not_null;
    varchar 'circle_name',  not_null;
    varchar 'circle_author',not_null;
    varchar 'day',          not_null;
    varchar 'area',         not_null;
    varchar 'circle_sym',   not_null;
    varchar 'circle_num',   not_null;
    varchar 'circle_flag',  not_null;
    varchar 'circlems',     not_null;
    varchar 'url',          not_null;
    varchar 'circle_type',  not_null;
    varchar 'circle_point';
    varchar 'comment';
    varchar 'serialized',   not_null;

    belongs_to 'circle_type', column => 'circle_type';

    add_index 'circle_idx_comiket_no'  => ['comiket_no'];
    add_index 'circle_idx_day'         => ['day'];
    add_index 'circle_idx_area'        => ['area'];
    add_index 'circle_idx_circle_sym'  => ['circle_sym'];
    add_index 'circle_idx_circle_type' => ['circle_type'];
};

create_table 'circle_type' => columns {
    integer 'id',          primary_key, auto_increment;
    varchar 'type_name',   not_null;
    varchar 'scheme',      not_null;
    varchar 'comment';
    integer 'created_at',  not_null;
};

create_table 'circle_book' => columns {
    integer 'id',          primary_key, auto_increment;
    varchar 'circle_id',   not_null;
    varchar 'book_name',   not_null;
    varchar 'comment';
    varchar 'created_by',  not_null;
    integer 'created_at',  not_null;
};

create_table 'circle_book_order' => columns {
    integer 'id',          primary_key, auto_increment;
    varchar 'circle_id',   not_null;
    varchar 'member_id',   not_null;
    integer 'count',       not_null;
    varchar 'comment';
    integer 'created_at',  not_null;
};

create_table 'action_log' => columns {
    integer 'id',          primary_key, auto_increment;
    varchar 'circle_id';
    varchar 'member_id';
    varchar 'message_id',  not_null;
    varchar 'parameters',  not_null;
    integer 'created_at',  not_null;

    add_index 'action_log_idx_circle_id' => ['circle_id'];
};

create_table 'assign_list' => columns {
    integer 'id',          primary_key, auto_increment;
    varchar 'name',        not_null;
    varchar 'member_id';
    varchar 'comiket_no',  not_null;
    integer 'created_at',  not_null;

    belongs_to 'member';
};

create_table 'assign' => columns {
    integer 'id',               primary_key, auto_increment;
    varchar 'circle_id',        not_null;
    varchar 'assign_list_id',   not_null;
    integer 'created_at',  not_null;

    belongs_to 'circle';
    belongs_to 'assign_list';

    add_unique_index 'assign_unique' => ['circle_id', 'assign_list_id'];
};

create_table 'notice' => columns {
    integer 'id',           primary_key, auto_increment;
    varchar 'key',          not_null;
    varchar 'title',        not_null;
    varchar 'text',         not_null;
    varchar 'member_id',    not_null;
    integer 'created_at',   not_null;

    belongs_to 'member';

    add_unique_index 'notice_unique' => ['key', 'created_at'];
};

1;
