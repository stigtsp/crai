unit module CRAI::Web::Layout;

use Template::Classic;

my $layout-template :=
template :(Str :$title, Str :$query, :@content), q:to/HTML/;
    <!DOCTYPE html>
    <meta charset="utf-8">
    <title>CRAI<%= $title.defined ?? “ — $title” !! ‘’ %></title>
    <link rel="stylesheet" href="/static/crai.css">
    <header class="crai--header">
        <a href="/" title="CRAI">CRAI</a>
        <form action="/search">
            <input type="search"
                   name="q"
                   placeholder="Search …"
                   value="<%= $query // ‘’ %>">
            <button type="submit">Search</button>
        </form>
    </header>
    <section class="crai--content">
        <% .take for @content; %>
    </section>
    <footer class="crai--footer">
        <p class="-legal">
            <a href="https://github.com/chloekek/crai">CRAI</a> is © 2019 Chloé Kekoa.
            <a href="https://raw.githubusercontent.com/perl6/mu/master/misc/camelia.txt">Camelia</a> is ™ Larry Wall.
            Archive names, descriptions, and other content are © their respective authors.
        </p>
    </footer>
    HTML

sub in-layout(|c)
    is export
{
    $layout-template(|c).eager.join;
}
