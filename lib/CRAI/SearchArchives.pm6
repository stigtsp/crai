=begin pod

=head1 NAME

CRAI::SearchArchives - Search archives in the database

=head1 SYNOPSIS

This use case is primarily invoked by the web interface. See the
C«CRAI::SearchArchives::Web» module for an example.

=head1 DESCRIPTION

Search archives using a user-supplied query. There is one search result for
the latest version of each matching I«distribution». The user can click
through to see the different archives for that distribution.

For details surrounding the search behavior, see the C«search.sql» resource.

=end pod

unit class CRAI::SearchArchives;

use CRAI::Database;
use CRAI::SearchArchives::Result;
use DBDish::StatementHandle;

has CRAI::Database $!db;

has DBDish::StatementHandle $!search-archives-sth;
my constant $search-archives-sql = %?RESOURCES<search.sql>.slurp;

method new(CRAI::Database:D $db --> ::?CLASS:D)
{
    self.bless(:$db);
}

submethod BUILD(:$!db --> Nil)
{
    $!search-archives-sth := $!db.sqlite.prepare($search-archives-sql);
}

method search-archives(::?CLASS:D: Str:D $query --> Seq:D)
{
    $!search-archives-sth.execute(
        $query.trim
        .subst(/\s+/, ‘::’, :g)
        .subst(/(<[%_\\]>)/, {“\\$0”}, :g)
    );

    $!search-archives-sth.allrows(:array-of-hash)
        ==> map({
            for %^r.kv -> $k, $v is rw { $v ||= Str unless $k eq ‘meta-depends’ }
            my @meta-tags = split(‘,’, %^r<meta-tags> // ‘’).grep(?*).sort;
            CRAI::SearchArchives::Result.new(|%^r, :@meta-tags);
        });
}

