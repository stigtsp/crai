unit module CRAI::Web::Search;

use CRAI::Web::Layout;
use Cro::HTTP::Router;
use Template::Classic;

my &search-results-template :=
template :(), q:to/HTML/;
    hello world
    HTML

our sub search(Str:D $query)
{
    my $title   := $query;
    my $content := search-results-template;
    content ‘text/html’, in-layout(:$title, :$query, :$content);
}
