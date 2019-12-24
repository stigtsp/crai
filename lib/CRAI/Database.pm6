unit class CRAI::Database;

use CRAI::Hash;
use DBDish::Connection;
use DBDish::StatementHandle;
use DBIish;
use JSON::Fast;
use Terminal::ANSIColor;

has DBDish::Connection $!sqlite;
has IO::Path           $!archives;

method new(|c)
{
    die ‘Use CRAI::Database.open instead’;
}

method open(IO::Path:D $path --> ::?CLASS:D)
{
    self.bless(:$path);
}

submethod BUILD(IO::Path:D :$path)
{
    $!archives = $path.child(‘archives’);
    $!archives.mkdir(mode => 0o755);

    $!sqlite = DBIish.connect(‘SQLite’, database => $path.child(‘sqlite’));

    $!sqlite.do(q:to/SQL/);
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
        );
        SQL

    $!sqlite.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_tags (
            archive_url             text    NOT NULL,
            meta_tag                text    NOT NULL,
            PRIMARY KEY (archive_url, meta_tag),
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        );
        SQL

    $!sqlite.do(q:to/SQL/);
        CREATE INDEX IF NOT EXISTS ix_meta_tags_meta_tag
            ON meta_tags (meta_tag)
        SQL

    $!sqlite.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS meta_depends (
            archive_url             text    NOT NULL,
            meta_depend             text    NOT NULL,
            PRIMARY KEY (archive_url, meta_depend),
            FOREIGN KEY (archive_url) REFERENCES archives (url)
        );
        SQL

    $!sqlite.do(q:to/SQL/);
        CREATE INDEX IF NOT EXISTS ix_meta_depends_meta_depend
            ON meta_depends (meta_depend)
        SQL

    # TODO: Create table for provides.
}

has DBDish::StatementHandle $!list-archives-sth;
method list-archives(::?CLASS:D: --> Seq:D)
{
    $!list-archives-sth //= $!sqlite.prepare(q:to/SQL/);
        SELECT url
        FROM archives
        SQL

    $!list-archives-sth.execute;

    $!list-archives-sth.allrows.map(*[0]);
}

class SearchResult
{
    has Str   $.meta-name;
    has Str   $.meta-version;
    has Str   $.meta-description;
    has Str   $.meta-license;
    has Str:D @.meta-tags;
    has Int   $.meta-depends;
}

has DBDish::StatementHandle $!search-archives-sth;
method search-archives(::?CLASS:D: Str:D $query --> Seq:D)
{
    $!search-archives-sth //= $!sqlite.prepare(q:to/SQL/);
        SELECT
            a.meta_name               AS "meta-name",
            a.meta_version            AS "meta-version",
            a.meta_description        AS "meta-description",
            a.meta_license            AS "meta-license",
            (
                SELECT group_concat(mu.meta_tag)
                FROM meta_tags AS mu
                WHERE mu.archive_url = a.url
            ) AS "meta-tags",
            (
                SELECT count(*)
                FROM meta_depends AS md
                WHERE md.archive_url = a.url
            ) AS "meta-depends"

        FROM
            archives AS a

        WHERE
            a.meta_name LIKE '%' || ?1 || '%' ESCAPE '\'
                OR
            EXISTS (
                SELECT NULL
                FROM meta_tags AS mt
                WHERE
                    mt.archive_url = a.url
                        AND
                    mt.meta_tag LIKE '%' || ?1 || '%' ESCAPE '\'
            )
        SQL

    given $query.trim {
        s:g/\s+/::/;
        s:g/(<[%_\\]>)/\\$0/;
        $!search-archives-sth.execute($_);
    }

    $!search-archives-sth.allrows(:array-of-hash)
        ==> map({
            for %^r.kv -> $k, $v is rw { $v ||= Str unless $k eq ‘meta-depends’ }
            my @meta-tags = split(‘,’, %^r<meta-tags> // ‘’).grep(?*).sort;
            SearchResult.new(|%^r, :@meta-tags);
        });
}

has DBDish::StatementHandle $!ensure-archive-sth;
method ensure-archive(::?CLASS:D: Str:D $url --> Nil)
{
    $!ensure-archive-sth //= $!sqlite.prepare(q:to/SQL/);
        INSERT INTO archives (url)
        VALUES ($1)
        ON CONFLICT (url) DO NOTHING
        SQL

    $!ensure-archive-sth.execute($url);

    if $!ensure-archive-sth.rows == 0 {
        log ‘blue’, ‘EXISTS’, $url;
    } else {
        log ‘green’, ‘NEW’, $url;
    }
}

method retrieve-archive(::?CLASS:D: Str:D $url --> Nil)
{
    my $filename := self!archive-path($url);
    if $filename ~~ :e {
        log ‘blue’, ‘EXISTS’, “$url @ $filename”;
    } else {
        log ‘green’, ‘NEW’, “$url → $filename”;
        run «curl --fail --location --output “$filename” “$url”»;
    }
}

has DBDish::StatementHandle $!ensure-hashes-sth;
method ensure-hashes(::?CLASS:D: Str:D $url --> Nil)
{
    my $filename := self!archive-path($url);

    $!ensure-hashes-sth //= $!sqlite.prepare(q:to/SQL/);
        UPDATE archives
        SET md5_hash    = ?2,
            sha1_hash   = ?3,
            sha256_hash = ?4
        WHERE url = ?1
        SQL

    my @hash-subs := &md5-file-hex, &sha1-file-hex, &sha256-file-hex;
    my $hashes    := @hash-subs.map: { $_($filename) };
    $!ensure-hashes-sth.execute($url, |$hashes);

    log ‘green’, ‘HASHED’, “$url @ $filename”;
}

has DBDish::StatementHandle $!ensure-meta-sth;
has DBDish::StatementHandle $!ensure-meta-tags-sth;
has DBDish::StatementHandle $!ensure-meta-depends-sth;
method ensure-meta(::?CLASS:D: Str:D $url --> Nil)
{
    my $filename := self!archive-path($url);

    $!ensure-meta-sth //= $!sqlite.prepare(q:to/SQL/);
        UPDATE archives
        SET meta_name        = ?2,
            meta_version     = ?3,
            meta_description = ?4,
            meta_source_url  = ?5,
            meta_license     = ?6
        WHERE url = ?1
        SQL

    $!ensure-meta-tags-sth //= $!sqlite.prepare(q:to/SQL/);
        INSERT INTO meta_tags (archive_url, meta_tag)
        VALUES (?1, ?2)
        ON CONFLICT (archive_url, meta_tag) DO NOTHING
        SQL

    $!ensure-meta-depends-sth //= $!sqlite.prepare(q:to/SQL/);
        INSERT INTO meta_depends (archive_url, meta_depend)
        VALUES (?1, ?2)
        ON CONFLICT (archive_url, meta_depend) DO NOTHING
        SQL

    log ‘blue’, ‘EXTRACTING’, “$url @ $filename”;

    my @tar := «tar --extract --to-stdout --gunzip
                --wildcards --file “$filename” */META6.json»;
    my $tar := run(@tar, :out);

    my $meta := try from-json($tar.out.slurp);
    if $! {
        log ‘red’, ‘FAILURE’, “$url @ $filename : $!”;
        return;
    }

    multi prefix:<~?>(Any:U $x) {  $x }
    multi prefix:<~?>(Any:D $x) { ~$x }
    $!ensure-meta-sth.execute(
        $url,
        ~?$meta<name>,
        ~?$meta<version>,
        ~?$meta<description>,
        ~?$meta<source-url>,
        ~?$meta<license>,
    );

    $!ensure-meta-tags-sth.execute($url, $_) for @($meta<tags> // ());

    for @($meta<depends> // ()) {
        try $!ensure-meta-depends-sth.execute($url, $_);
        log ‘yellow’, ‘WARNING’, ~$! if $!;
    }

    log ‘green’, ‘EXTRACTED’, “$url @ $filename”;
}

method !archive-path(::?CLASS:D: Str:D $url --> IO::Path:D)
{
    my $url-hash := sha256-hex($url);
    $!archives.child($url-hash);
}

sub log(Str:D $color, Str:D $status, Str:D $message --> Nil)
{
    note color($color), “[$status]”, color(‘reset’), ‘ ’, $message;
}
