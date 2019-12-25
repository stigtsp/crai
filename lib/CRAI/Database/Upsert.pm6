unit role CRAI::Database::Upsert;

use CRAI::Util::Hash;
use DBDish::Connection;
use DBDish::StatementHandle;
use JSON::Fast;
use Terminal::ANSIColor;

method sqlite(--> DBDish::Connection:D) { … }
method archives(--> IO::Path:D) { … }

sub log(Str:D $color, Str:D $status, Str:D $message --> Nil)
{
    note color($color), “[$status]”, color(‘reset’), ‘ ’, $message;
}

method archive-path(::?CLASS:D: Str:D $url --> IO::Path:D)
{
    my $url-hash := sha256-hex($url);
    $.archives.child($url-hash);
}

has DBDish::StatementHandle $!list-archives-sth;
method list-archives(::?CLASS:D: --> Seq:D)
{
    $!list-archives-sth //= $.sqlite.prepare(q:to/SQL/);
        SELECT url
        FROM archives
        SQL

    $!list-archives-sth.execute;

    $!list-archives-sth.allrows.map(*[0]);
}

has DBDish::StatementHandle $!ensure-archive-sth;
method ensure-archive(::?CLASS:D: Str:D $url --> Nil)
{
    $!ensure-archive-sth //= $.sqlite.prepare(q:to/SQL/);
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
    my $filename := self.archive-path($url);
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
    my $filename := self.archive-path($url);

    $!ensure-hashes-sth //= $.sqlite.prepare(q:to/SQL/);
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
    my $filename := self.archive-path($url);

    $!ensure-meta-sth //= $.sqlite.prepare(q:to/SQL/);
        UPDATE archives
        SET meta_name        = ?2,
            meta_version     = ?3,
            meta_description = ?4,
            meta_source_url  = ?5,
            meta_license     = ?6
        WHERE url = ?1
        SQL

    $!ensure-meta-tags-sth //= $.sqlite.prepare(q:to/SQL/);
        INSERT INTO meta_tags (archive_url, meta_tag)
        VALUES (?1, ?2)
        ON CONFLICT (archive_url, meta_tag) DO NOTHING
        SQL

    $!ensure-meta-depends-sth //= $.sqlite.prepare(q:to/SQL/);
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
