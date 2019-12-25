=begin pod

=head1 NAME

CRAI::RetrieveArchiveList - Insert archive list into database

=head1 DESCRIPTION

Retrieve an archive list using an archive listing,
and ensure each such archive is present in the database.

=end pod

unit class CRAI::RetrieveArchiveList;

use CRAI::ArchiveListing;
use CRAI::Database;
use CRAI::Util::Log;
use DBDish::StatementHandle;

has CRAI::Database $!db;

has DBDish::StatementHandle $!ensure-archive-sth;
my constant $ensure-archive-sql = q:to/SQL/;
    INSERT INTO archives (url)
    VALUES ($1)
    ON CONFLICT (url) DO NOTHING
    SQL

method new(CRAI::Database:D $db --> ::?CLASS:D)
{
    self.bless(:$db);
}

submethod BUILD(:$!db --> Nil)
{
    $!ensure-archive-sth := $!db.sqlite.prepare($ensure-archive-sql);
}

method retrieve-archive-list(::?CLASS:D: CRAI::ArchiveListing $listing --> Nil)
{
    self!ensure-archive($_) for $listing.archives;
}

method !ensure-archive(::?CLASS:D: Str:D $url --> Nil)
{
    $!ensure-archive-sth.execute($url);
    if $!ensure-archive-sth.rows == 0 {
        log ‘blue’, ‘EXISTS’, $url;
    } else {
        log ‘green’, ‘NEW’, $url;
    }
}
