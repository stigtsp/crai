=begin pod

=head1 NAME

CRAI::RetrieveArchiveList - Insert archive list into database

=head1 SYNOPSIS

For an example, see the signature and definition of MAIN.

=head1 DESCRIPTION

This use case retrieves B«a list of» archive URLs, and stores each archive
URL in the database.

This use case B«does not» involve downloading the archives themselves. That
is the job of the C«CRAI::RetrieveArchives» use case.

=end pod

unit class CRAI::RetrieveArchiveList;

use CRAI::ArchiveListing::CPAN;
use CRAI::ArchiveListing::Ecosystem;
use CRAI::ArchiveListing;
use CRAI::Database;
use CRAI::Util::Log;
use DBDish::StatementHandle;

multi MAIN(‘retrieve-archive-list’, Str:D $from, IO() :$database-path! --> Nil)
    is export(:main)
{
    my $archive-listing := do given $from {
        when ‘cpan’      { CRAI::ArchiveListing::CPAN.new      }
        when ‘ecosystem’ { CRAI::ArchiveListing::Ecosystem.new }
        default { die “Unknown archive listing: $from” }
    };
    my $database := CRAI::Database.open($database-path);
    my $retrieve-archive-list := CRAI::RetrieveArchiveList.new($database);
    $retrieve-archive-list.retrieve-archive-list($archive-listing);
}

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
