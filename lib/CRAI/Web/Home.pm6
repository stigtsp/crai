unit module CRAI::Web::Home;

use CRAI::Web::Layout;
use Cro::HTTP::Router;
use Template::Classic;

my &home-template :=
template :(), q:to/HTML/;
    <article class="crai--home">
        <h1>Comprehensive Raku Archive Index</h1>
        <img alt="CRAI" src="/static/crai.svg">
    </article>
    HTML

our sub home
{
    my $content := home-template;
    content ‘text/html’, in-layout(:$content);
}
