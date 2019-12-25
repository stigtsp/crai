unit module CRAI::Database::Schema;

use DBDish::Connection;

our sub install(DBDish::Connection $sqlite --> Nil)
{
    $sqlite.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS archives (
            url                     text    NOT NULL,

            md5_hash                text,
            sha1_hash               text,
            sha256_hash             text,

            meta_name               text,
            meta_version            text,
            meta_description        text,
            meta_source_url         text,
            meta_license            text,

            PRIMARY KEY (url)
        )
        SQL

    $sqlite.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_tags (
            archive_url             text    NOT NULL,
            meta_tag                text    NOT NULL,
            PRIMARY KEY (archive_url, meta_tag),
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $sqlite.do(q:to/SQL/);
        CREATE INDEX IF NOT EXISTS ix_meta_tags_meta_tag
            ON meta_tags (meta_tag)
        SQL

    $sqlite.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_depends (
            archive_url             text    NOT NULL,
            meta_depend             text    NOT NULL,
            PRIMARY KEY (archive_url, meta_depend),
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        )
        SQL

    $sqlite.do(q:to/SQL/);
        CREATE INDEX IF NOT EXISTS ix_meta_depends_meta_depend
            ON meta_depends (meta_depend)
        SQL

    # TODO: Create table for provides.
}
