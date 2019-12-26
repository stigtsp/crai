unit module CRAI::SearchArchives::Web;

use CRAI::SearchArchives;
use CRAI::Web::Layout;
use Cro::HTTP::Router;
use Template::Classic;

my &search-results-template :=
template :(:@search-results), q:to/HTML/;
    <p class="crai--warning">
        Version numbers in search results are currently wrong.
        See <a href="https://github.com/chloekek/crai/issues/6">#6</a>.
    </p>
    <% for @search-results -> $search-result { %>
        <article class="crai--search-result">
            <h1>
                <% my $title; %>

                <% with $search-result.meta-name { %>
                    <% ++$title; %>
                    <a class="-name" href="<%= $search-result.distribution-link %>"><%= $_ %></a>
                <% } %>

                <% with $search-result.meta-version { %>
                    <% ++$title; %>
                    <a class="-version" href="<%= $search-result.version-link %>"><%= $_ %></a>
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
                <a class="-tag -archive-link" href="<%= $search-result.archive-link %>">archive</a>

                <% given $search-result.meta-depends { %>
                    <span class="
                        -tag
                        -depends
                        <% take ‘-none’  when 0 .. 0 %>
                        <% take ‘-few’   when 1 .. 2 %>
                        <% take ‘-quite’ when 3 .. 4 %>
                        <% take ‘-many’  when 5 .. ∞ %>
                    "><%= $_ %> dep<%= $_ == 1 ?? ‘’ !! ‘s’ %></span>
                <% } %>

                <% with $search-result.meta-license { %>
                    <span class="-tag -license"><%= $_ %></span>
                <% } %>

                <% for $search-result.meta-tags { %>
                    <span class="-tag"><%= $_ %></span>
                <% } %>
            </section>
        </article>
    <% } %>
    HTML

our sub search-archives(&db, Str:D $query is copy)
{
    $query .= trim;
    return redirect :see-other, ‘/’ unless $query;

    my $search-archives := CRAI::SearchArchives.new(db);
    my @search-results = $search-archives.search-archives($query);

    my $title   := $query;
    my $content := search-results-template(:@search-results);
    content ‘text/html’, in-layout(:$title, :$query, :$content);
}
