unit role CRAI::Database::Upsert;

use CRAI::Util::Hash;
use CRAI::Util::Log;
use DBDish::Connection;
use DBDish::StatementHandle;

method sqlite(::?CLASS:D: --> DBDish::Connection:D) { … }
method archive-path(::?CLASS:D: Str:D --> IO::Path:D) { … }

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
