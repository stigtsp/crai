unit class CRAI::ViewArchive;

use CRAI::Database;
use CRAI::ViewArchive::Archive;
use DBDish::StatementHandle;

has CRAI::Database $!db;

has DBDish::StatementHandle $!find-archive-sth;
my constant $find-archive-sql = q:to/SQL/;
    SELECT
        url                 AS "url",
        md5_hash            AS "md5-hash",
        sha1_hash           AS "sha1-hash",
        sha256_hash         AS "sha256-hash",
        meta_name           AS "meta-name",
        meta_version        AS "meta-version",
        meta_description    AS "meta-description",
        meta_source_url     AS "meta-source-url",
        meta_license        AS "meta-license"

    FROM
        archives

    WHERE
        url = ?1
    SQL

method new(CRAI::Database:D $db --> ::?CLASS:D)
{
    self.bless(:$db);
}

submethod BUILD(:$!db --> Nil)
{
    $!find-archive-sth := $!db.sqlite.prepare($find-archive-sql);
}

method view-archive(::?CLASS:D: Str:D $url --> CRAI::ViewArchive::Archive:D)
{
    $!find-archive-sth.execute($url);
    my %row = $!find-archive-sth.row(:hash);
    return Nil unless %row;
    for %row.kv -> $k, $v is rw { $v ||= Str }
    CRAI::ViewArchive::Archive.new(|%row);
}
