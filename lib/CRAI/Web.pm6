unit module CRAI::Web;

use Cro::HTTP::Router;
use Cro::HTTP::Server;

our sub application
{
    route {
        get -> {
            content ‘text/html’, ｢Hello, world!｣;
        }
    }
}

our sub serve(Str:D $host, Int:D $port --> Nil)
{
    my $application := application;
    my $service := Cro::HTTP::Server.new(:$host, :$port, :$application);
    $service.start;
    sleep;
}
