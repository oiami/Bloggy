--
-- File generated with SQLiteStudio v3.0.7 on Tue Dec 22 14:45:33 2015
--
-- Text encoding used: UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: comment
DROP TABLE IF EXISTS comment;

CREATE TABLE comment (
    id      INTEGER PRIMARY KEY AUTOINCREMENT
                    UNIQUE
                    NOT NULL,
    content VARCHAR NOT NULL,
    author  INTEGER NOT NULL
                    CONSTRAINT comment_author_user_id REFERENCES user (id),
    post    INTEGER CONSTRAINT comment_post_id REFERENCES blog (id) 
                    NOT NULL
);


-- Table: post
DROP TABLE IF EXISTS post;

CREATE TABLE post (
    id      INTEGER PRIMARY KEY AUTOINCREMENT
                    UNIQUE
                    NOT NULL,
    title   VARCHAR NOT NULL,
    content VARCHAR,
    blog    INTEGER CONSTRAINT post_blog_id REFERENCES blog (id),
    author  INTEGER CONSTRAINT post_user_id REFERENCES user (id) 
);


-- Table: blog
DROP TABLE IF EXISTS blog;

CREATE TABLE blog (
    id     INTEGER PRIMARY KEY AUTOINCREMENT
                   NOT NULL
                   UNIQUE,
    title  VARCHAR NOT NULL,
    url    VARCHAR NOT NULL
                   UNIQUE,
    author INTEGER CONSTRAINT blog_user_id REFERENCES user (id) 
);


-- Table: user
DROP TABLE IF EXISTS user;

CREATE TABLE user (
    id       INTEGER      PRIMARY KEY AUTOINCREMENT
                          UNIQUE
                          NOT NULL,
    username VARCHAR (50) UNIQUE
                          NOT NULL,
    email    VARCHAR      UNIQUE
                          NOT NULL,
    password VARCHAR      NOT NULL
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
