unit module CRAI::Main;

use CRAI::ArchiveListing::CPAN;
use CRAI::ArchiveListing::Ecosystem;
use CRAI::Database;
use CRAI::ExtractMetadata;
use CRAI::RetrieveArchiveList;
use CRAI::Web;

multi MAIN(‘retrieve-archive-list’, Str:D $from, IO() :$database-path! --> Nil)
    is export
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

multi MAIN(‘retrieve-archives’, IO() :$database-path! --> Nil)
    is export
{
    my $database := CRAI::Database.open($database-path);
    for $database.list-archives -> $url {
        $database.retrieve-archive($url);
    }
}

multi MAIN(‘compute-archive-hashes’, IO() :$database-path! --> Nil)
    is export
{
    my $database := CRAI::Database.open($database-path);
    for $database.list-archives -> $url {
        $database.ensure-hashes($url);
    }
}

multi MAIN(‘extract-metadata’, IO() :$database-path! --> Nil)
    is export
{
    my $database := CRAI::Database.open($database-path);
    my $extract-metadata := CRAI::ExtractMetadata.new($database);
    $extract-metadata.extract-metadata;
}

multi MAIN(‘serve’, Str:D $host, Int:D $port, IO() :$database-path! --> Nil)
    is export
{
    my &db := { CRAI::Database.open($database-path) };
    CRAI::Web::serve(&db, $host, $port);
}
