CREATE TABLE member (
    id              VARCHAR PRIMARY KEY NOT NULL,
    member_id       VARCHAR NOT NULL UNIQUE,
    member_name     VARCHAR,
    image_url       VARCHAR NOT NULL,
    created_at      DATETIME DEFAULT (DATETIME('now','localtime'))
);
------------------------
CREATE TABLE member_role (
    id              INTEGER PRIMARY KEY,
    member_id       VARCHAR NOT NULL,
    role_type       VARCHAR NOT NULL,
    created_at      DATETIME DEFAULT (DATETIME('now','localtime')),
    UNIQUE(member_id,role_type)
);
------------------------
CREATE TABLE checklist (
    id             INTEGER PRIMARY KEY NOT NULL,
    circle_id      VARCHAR NOT NULL,
    member_id      VARCHAR NOT NULL,
    count          INTEGER NOT NULL,
    comment        VARCHAR,
    created_at     DATETIME DEFAULT (DATETIME('now','localtime')),
    UNIQUE(circle_id,member_id)
);
------------------------
CREATE TABLE circle (
    id            VARCHAR PRIMARY KEY NOT NULL,
    comiket_no    VARCHAR NOT NULL,
    circle_name   VARCHAR NOT NULL,
    circle_author VARCHAR NOT NULL,
    day           VARCHAR NOT NULL,
    area          VARCHAR NOT NULL,
    circle_sym    VARCHAR NOT NULL,
    circle_num    VARCHAR NOT NULL,
    circle_flag   VARCHAR NOT NULL,
    circlems      VARCHAR NOT NULL,
    url           VARCHAR NOT NULL,
    circle_type   VARCHAR DEFAULT NULL,
    circle_point  INTEGER DEFAULT 0,
    comment       VARCHAR,
    serialized    VARCHAR NOT NULL
);

CREATE INDEX IDX_circle_comiket_no  ON circle(comiket_no);
CREATE INDEX IDX_circle_day         ON circle(day);
CREATE INDEX IDX_circle_area        ON circle(area);
CREATE INDEX IDX_circle_circle_sym  ON circle(circle_sym);
CREATE INDEX IDX_circle_circle_type ON circle(circle_type);
------------------------
CREATE TABLE circle_type (
    id          INTEGER PRIMARY KEY NOT NULL,
    type_name   VARCHAR NOT NULL,
    scheme      VARCHAR NOT NULL,
    comment     VARCHAR,
    created_at  DATETIME DEFAULT (DATETIME('now','localtime'))
);
------------------------
CREATE TABLE action_log (
    id          INTEGER PRIMARY KEY,
    circle_id   INTEGER,
    message_id  VARCHAR NOT NULL,
    parameters  VARCHAR NOT NULL,
    created_at  DATETIME DEFAULT (DATETIME('now','localtime'))
);

CREATE INDEX IDX_action_log_circle_id ON action_log(circle_id);
------------------------
CREATE TABLE assign_list (
    id          INTEGER PRIMARY KEY,
    name        VARCHAR NOT NULL,
    member_id   VARCHAR,
    comiket_no  VARCHAR NOT NULL,
    created_at  DATETIME DEFAULT (DATETIME('now','localtime'))
);
------------------------
CREATE TABLE assign (
    id              INTEGER PRIMARY KEY,
    circle_id       VARCHAR NOT NULL,
    assign_list_id  INTEGER NOT NULL,
    created_at  DATETIME DEFAULT (DATETIME('now','localtime')),
    UNIQUE(circle_id,assign_list_id)
);
------------------------
CREATE TABLE notice (
    id          INTEGER PRIMARY KEY,
    key         VARCHAR NOT NULL,
    title       VARCHAR NOT NULL,
    text        VARCHAR NOT NULL,
    member_id   VARCHAR NOT NULL,
    created_at  DATETIME DEFAULT (DATETIME('now','localtime')),
    UNIQUE(key,created_at)
);
