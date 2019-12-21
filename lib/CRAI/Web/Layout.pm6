unit module CRAI::Web::Layout;

use Template::Classic;

my $layout-template :=
template :(Str :$title, Str :$query, :@content), q:to/HTML/;
    <!DOCTYPE html>
    <meta charset="utf-8">
    <title>CRAI<%= $title.defined ?? “ — $title” !! ‘’ %></title>
    <form action="/search">
        <input type="search"
               name="q"
               placeholder="Search …"
               value="<%= $query // ‘’ %>">
        <button type="submit">Search</button>
    </form>
    <% .take for @content; %>
    HTML

sub in-layout(|c)
    is export
{
    $layout-template(|c).eager.join;
}
