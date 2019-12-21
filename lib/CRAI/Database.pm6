unit class CRAI::Database;

use DBDish::Connection;
use DBDish::StatementHandle;
use DBIish;
use Digest::SHA:from<Perl5> <sha256_hex>;
use Digest::file:from<Perl5> <digest_file_hex>;
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
    $!sqlite   = DBIish.connect(‘SQLite’, database => $path.child(‘sqlite’));
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
    # TODO: Create table for depends.
    # TODO: Create table for provides.

    $!archives = $path.child(‘archives’);
    $!archives.mkdir;
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

    my $hashes := <MD5 SHA-1 SHA-256>.map: { digest_file_hex($filename, $_) };
    $!ensure-hashes-sth.execute($url, |$hashes);

    log ‘green’, ‘HASHED’, “$url @ $filename”;
}

method !archive-path(::?CLASS:D: Str:D $url --> IO::Path:D)
{
    my $url-hash := sha256_hex($url);
    $!archives.child($url-hash);
}

sub log(Str:D $color, Str:D $status, Str:D $message --> Nil)
{
    note color($color), “[$status]”, color(‘reset’), ‘ ’, $message;
}
