unit module CRAI::Web;

use CRAI::Web::Home;
use CRAI::Web::Search;
use Cro::HTTP::Router;
use Cro::HTTP::Server;

our sub application(&db)
{
    route {
        get -> { CRAI::Web::Home::home };
        get -> ‘search’, :$q { CRAI::Web::Search::search(&db, $q) };
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
