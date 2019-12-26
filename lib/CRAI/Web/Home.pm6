unit module CRAI::Web::Home;

use CRAI::Web::Layout;
use Cro::HTTP::Router;
use Template::Classic;

my &home-template :=
template :(), q:to/HTML/;
    <article class="crai--home">
        <h1>Comprehensive Raku Archive Index</h1>
        <img alt="CRAI" src="/static/crai.svg">
        <section>
            <p>
                The <strong>Comprehensive Raku Archive Index</strong> project
                collects information about <a href="https://raku.org">Raku</a>
                libraries hosted on CPAN and GitHub.

                By including permanent archive URLs and cryptographic
                hashes, the information collected is sufficient to enable
                reproducible builds, even if an author releases a new version
                of their library, or sneakily rewrites a Git tag!

                Reproducible builds are vital for fearless deployments and
                secure operation of production software systems.
            </p>
            <p>
                This project is very much a work-in-progress. Do not expect
                everything to work! At the top of the page you find a search bar,
                where you can search for libraries.
            </p>
        </section>
    </article>
    HTML

our sub home
{
    my $content := home-template;
    content ‘text/html’, in-layout(:$content);
}
