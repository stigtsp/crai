=begin pod

=head1 NAME

CRAI::ExtractMetadata - Extract metadata from archives

=head1 SYNOPSIS

For an example, see the signature and definition of MAIN.

=head1 DESCRIPTION

After downloading the archives with the C«CRAI::RetrieveArchives» use case,
metadata needs to be extracted from the archives. This use case takes care of
that.

For each archive that has been downloaded, extract its metadata and store it
in the database. Metadata, in this sense, is the data stored in the
I«META6.json» file of an archive.

Users of CRAI may use the metadata to discover what an archive is about, and
to associate various archives with each other, e.g. when they implement
different versions of a distribution.

=end pod

unit class CRAI::ExtractMetadata;

use CRAI::Database;
use CRAI::Util::Log;
use DBDish::StatementHandle;
use JSON::Fast;

has CRAI::Database $!db;

has DBDish::StatementHandle $!list-archives-sth;
my constant $list-archives-sql = q:to/SQL/;
    SELECT url
    FROM archives
    SQL

has DBDish::StatementHandle $!update-meta-sth;
my constant $update-meta-sql = q:to/SQL/;
    UPDATE archives
    SET meta_name        = ?2,
        meta_version     = ?3,
        meta_description = ?4,
        meta_source_url  = ?5,
        meta_license     = ?6
    WHERE url = ?1
    SQL

has DBDish::StatementHandle $!ensure-meta-tags-sth;
my constant $ensure-meta-tags-sql = q:to/SQL/;
    INSERT INTO meta_tags (archive_url, meta_tag)
    VALUES (?1, ?2)
    ON CONFLICT (archive_url, meta_tag) DO NOTHING
    SQL

has DBDish::StatementHandle $!ensure-meta-depends-sth;
my constant $ensure-meta-depends-sql = q:to/SQL/;
    INSERT INTO meta_depends (archive_url, meta_depend)
    VALUES (?1, ?2)
    ON CONFLICT (archive_url, meta_depend) DO NOTHING
    SQL

method new(CRAI::Database:D $db --> ::?CLASS:D)
{
    self.bless(:$db);
}

submethod BUILD(:$!db --> Nil)
{
    $!list-archives-sth       := $!db.sqlite.prepare($list-archives-sql);
    $!update-meta-sth         := $!db.sqlite.prepare($update-meta-sql);
    $!ensure-meta-tags-sth    := $!db.sqlite.prepare($ensure-meta-tags-sql);
    $!ensure-meta-depends-sth := $!db.sqlite.prepare($ensure-meta-depends-sql);
}

multi method extract-metadata(::?CLASS:D: --> Nil)
{
    $!list-archives-sth.execute;
    for $!list-archives-sth.allrows -> ($url) {
        self.extract-metadata($url);
    }
}

multi method extract-metadata(::?CLASS:D: Str:D $url --> Nil)
{
    my $filename := $!db.archive-path($url);

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
    $!update-meta-sth.execute(
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

multi MAIN(‘extract-metadata’, IO() :$database-path! --> Nil)
    is export(:main)
{
    my $database := CRAI::Database.open($database-path);
    my $extract-metadata := CRAI::ExtractMetadata.new($database);
    $extract-metadata.extract-metadata;
}
