=begin pod

=head1 NAME

CRAI::ComputeArchiveHashes - Compute and store archive hashes

=head1 SYNOPSIS

For an example, see the signature and definition of MAIN.

=head1 DESCRIPTION

After downloading the archives with the C«CRAI::RetrieveArchives» use case,
the archives need to be hashed. This use case takes care of that.

MD5, SHA-1, and SHA-256 cryptographic hashes are computed for each archive
that has been downloaded. Subsequently, these hashes are stored in the
database.

Users of CRAI may take advantage of the hashes to verify that the archive
they downloaded is the archive they expect. This is necessary for secure
deployments.

=end pod

unit class CRAI::ComputeArchiveHashes;

use CRAI::Database;
use CRAI::Util::Hash;
use CRAI::Util::Log;
use DBDish::StatementHandle;

multi MAIN(‘compute-archive-hashes’, IO() :$database-path! --> Nil)
    is export(:main)
{
    my $database := CRAI::Database.open($database-path);
    my $compute-archive-hashes := CRAI::ComputeArchiveHashes.new($database);
    $compute-archive-hashes.compute-archive-hashes;
}

has CRAI::Database $!db;

has DBDish::StatementHandle $!list-archives-sth;
my constant $list-archives-sql = q:to/SQL/;
    SELECT url
    FROM archives
    SQL

has DBDish::StatementHandle $!ensure-hashes-sth;
my constant $ensure-hashes-sql = q:to/SQL/;
    UPDATE archives
    SET md5_hash    = ?2,
        sha1_hash   = ?3,
        sha256_hash = ?4
    WHERE url = ?1
    SQL

method new(CRAI::Database:D $db --> ::?CLASS:D)
{
    self.bless(:$db);
}

submethod BUILD(:$!db --> Nil)
{
    $!list-archives-sth := $!db.sqlite.prepare($list-archives-sql);
    $!ensure-hashes-sth := $!db.sqlite.prepare($ensure-hashes-sql);
}

method compute-archive-hashes(::?CLASS:D: --> Nil)
{
    $!list-archives-sth.execute;
    for $!list-archives-sth.allrows -> ($url) {
        self!ensure-hashes($url);
    }
}

method !ensure-hashes(::?CLASS:D: Str:D $url --> Nil)
{
    my $filename := $!db.archive-path($url);

    my @hash-subs := &md5-file-hex, &sha1-file-hex, &sha256-file-hex;
    my $hashes    := @hash-subs.map: { $_($filename) };
    $!ensure-hashes-sth.execute($url, |$hashes);

    log ‘green’, ‘HASHED’, “$url @ $filename”;
}
