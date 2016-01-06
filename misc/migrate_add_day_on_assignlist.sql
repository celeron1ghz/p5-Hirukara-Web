CREATE TEMPORARY TABLE _assign_list (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  member_id VARCHAR(255),
  comiket_no VARCHAR(255) NOT NULL,
  created_at INTEGER NOT NULL
);

INSERT INTO _assign_list select * from assign_list;

DROP TABLE assign_list;

CREATE TABLE assign_list (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  member_id VARCHAR(255),
  day INTEGER NOT NULL,
  comiket_no VARCHAR(255) NOT NULL,
  created_at INTEGER NOT NULL
);

INSERT INTO assign_list

select 
  id,
  name,
  member_id,
  1,
  comiket_no,
  created_at
from _assign_list;
