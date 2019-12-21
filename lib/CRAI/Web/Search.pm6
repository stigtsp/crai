unit module CRAI::Web::Search;

use CRAI::Web::Layout;
use Cro::HTTP::Router;
use Template::Classic;

my &search-results-template :=
template :(:@search-results), q:to/HTML/;
    <% for @search-results -> $search-result { %>
        <article class="crai--search-result">
            <h1>
                <% my $title; %>

                <% with $search-result.meta-name { %>
                    <% ++$title; %>
                    <span class="-name"><%= $_ %></span>
                <% } %>

                <% with $search-result.meta-version { %>
                    <% ++$title; %>
                    <span class="-version"><%= $_ %></span>
                <% } %>

                <% with $search-result.meta-description { %>
                    <% ++$title; %>
                    <span class="-description"><%= $_ %></span>
                <% } %>

                <% unless $title { %>
                    <em class="-missing-name">(Missing name)</em>
                <% } %>
            </h1>

            <section class="-tags">
                <% with $search-result.meta-license { %>
                    <span class="-tag -license"><%= $_ %></span>
                <% } %>
            </section>
        </article>
    <% } %>
    HTML

our sub search(&db, Str:D $query is copy)
{
    $query .= trim;
    return redirect :see-other, ‘/’ unless $query;

    my @search-results = db.search-archives($query);

    my $title   := $query;
    my $content := search-results-template(:@search-results);
    content ‘text/html’, in-layout(:$title, :$query, :$content);
}
