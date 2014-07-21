CREATE TABLE member (
    id          INTEGER PRIMARY KEY NOT NULL,
    member_id   VARCHAR NOT NULL UNIQUE,
    image_url   VARCHAR NOT NULL,
    created_at  DATETIME DEFAULT (DATETIME('now','localtime'))
);

CREATE TABLE checklist (
    id             INTEGER PRIMARY KEY NOT NULL,
    circle_id      VARCHAR NOT NULL,
    member_id      VARCHAR NOT NULL,
    count          INTEGER NOT NULL,
    comment        VARCHAR,
    assign_to      VARCHAR NOT NULL,
    created_at     DATETIME DEFAULT (DATETIME('now','localtime')),
    UNIQUE(circle_id,member_id)
);

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
    comment       VARCHAR
);
