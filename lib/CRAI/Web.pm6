unit module CRAI::Web;

use CRAI::Database;
use CRAI::SearchArchives::Web;
use CRAI::ViewArchive::Web;
use CRAI::Web::Home;
use Cro::HTTP::Router;
use Cro::HTTP::Server;

our sub application(&db)
{
    route {
        get -> { CRAI::Web::Home::home };
        get -> ‘archive’, :$url { CRAI::ViewArchive::Web::view-archive(&db, $url) };
        get -> ‘search’, :$q { CRAI::SearchArchives::Web::search-archives(&db, $q) };
        get -> ‘static’, ‘crai.css’ { static %?RESOURCES<crai.css> };
        get -> ‘static’, ‘crai.svg’ { static %?RESOURCES<crai.svg> };
    }
}

our sub serve($db, Str:D $host, Int:D $port --> Nil)
{
    my $application := application($db);
    my $service := Cro::HTTP::Server.new(:$host, :$port, :$application);
    $service.start;
    sleep;
}

multi MAIN(‘serve’, Str:D $host, Int:D $port, IO() :$database-path! --> Nil)
    is export(:main)
{
    my &db := { CRAI::Database.open($database-path) };
    CRAI::Web::serve(&db, $host, $port);
}
