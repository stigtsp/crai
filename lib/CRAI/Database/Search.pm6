unit role CRAI::Database::Search;

use CRAI::Database::Search::Result;
use DBDish::Connection;
use DBDish::StatementHandle;

method sqlite(--> DBDish::Connection:D) { … }
method archives(--> IO::Path:D) { … }

has DBDish::StatementHandle $!search-archives-sth;
method search-archives(::?CLASS:D: Str:D $query --> Seq:D)
{
    my $sql := BEGIN { %?RESOURCES<search.sql>.slurp };
    $!search-archives-sth //= self.sqlite.prepare($sql);

    $!search-archives-sth.execute(
        $query.trim
        .subst(/\s+/, ‘::’, :g)
        .subst(/(<[%_\\]>)/, {“\\$0”}, :g)
    );

    $!search-archives-sth.allrows(:array-of-hash)
        ==> map({
            for %^r.kv -> $k, $v is rw { $v ||= Str unless $k eq ‘meta-depends’ }
            my @meta-tags = split(‘,’, %^r<meta-tags> // ‘’).grep(?*).sort;
            CRAI::Database::Search::Result.new(|%^r, :@meta-tags);
        });
}

