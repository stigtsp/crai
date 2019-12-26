=begin pod

=head1 NAME

CRAI::RetrieveArchives - Download archives if necessary

=head1 SYNOPSIS

For an example, see the signature and definition of MAIN.

=head1 DESCRIPTION

After retrieving the list of archives using the C«CRAI::RetrieveArchiveList»
use case, the archives themselves must be downloaded. This use case takes
care of that.

=end pod

unit class CRAI::RetrieveArchives;

use CRAI::Database;
use CRAI::Util::Log;
use DBDish::StatementHandle;

multi MAIN(‘retrieve-archives’, IO() :$database-path! --> Nil)
    is export(:main)
{
    my $database := CRAI::Database.open($database-path);
    my $retrieve-archives := CRAI::RetrieveArchives.new($database);
    $retrieve-archives.retrieve-archives;
}

has CRAI::Database $!db;

has DBDish::StatementHandle $!list-archives-sth;
my constant $list-archives-sql = q:to/SQL/;
    SELECT url
    FROM archives
    SQL

method new(CRAI::Database:D $db --> ::?CLASS:D)
{
    self.bless(:$db);
}

submethod BUILD(:$!db --> Nil)
{
    $!list-archives-sth := $!db.sqlite.prepare($list-archives-sql);
}

method retrieve-archives(::?CLASS:D: --> Nil)
{
    $!list-archives-sth.execute;
    for $!list-archives-sth.allrows -> ($url) {
        self!retrieve-archive($url);
    }
}

method !retrieve-archive(::?CLASS:D: Str:D $url --> Nil)
{
    my $filename := $!db.archive-path($url);
    if $filename ~~ :e {
        log ‘blue’, ‘EXISTS’, “$url @ $filename”;
    } else {
        log ‘green’, ‘NEW’, “$url → $filename”;
        run «curl --fail --location --output “$filename” “$url”»;
    }
}
