unit module CRAI::ViewArchive::Web;

use CRAI::ViewArchive;
use CRAI::Web::Layout;
use Cro::HTTP::Router;
use Template::Classic;

my &archive-template :=
template :($archive), q:to/HTML/;
    <article class="crai--archive">
        <h1>Archive <%= $archive.url %></h1>
        <table class="-archive">
            <tr class="-url">
                <th>URL</th>
                <td><%= $archive.url %></td>
            </tr>
            <tr class="-mirror-url">
                <th>Mirror URL</th>
                <td><%= $archive.mirror-url %></td>
            </tr>
            <tr class="-md5-hash">
                <th>MD5 hash</th>
                <td><%= $archive.md5-hash // ‘’ %></td>
            </tr>
            <tr class="-sha1-hash">
                <th>SHA-1 hash</th>
                <td><%= $archive.sha1-hash // ‘’ %></td>
            </tr>
            <tr class="-sha256-hash">
                <th>SHA-256 hash</th>
                <td><%= $archive.sha256-hash // ‘’ %></td>
            </tr>
        </table>
        <table class="-distribution">
            <tr class="-meta-name">
                <th>Name</th>
                <td><%= $archive.meta-name // ‘’ %></td>
            </tr>
            <tr class="-meta-version">
                <th>Version</th>
                <td><%= $archive.meta-version // ‘’ %></td>
            </tr>
            <tr class="-meta-description">
                <th>Description</th>
                <td><%= $archive.meta-description // ‘’ %></td>
            </tr>
            <tr class="-meta-source-url">
                <th>Source URL</th>
                <td><%= $archive.meta-source-url // ‘’ %></td>
            </tr>
            <tr class="-meta-license">
                <th>License</th>
                <td><%= $archive.meta-license // ‘’ %></td>
            </tr>
        </table>
    </article>
    HTML

our sub view-archive(&db, Str:D $url)
{
    my $view-archive := CRAI::ViewArchive.new(db);
    my $archive := $view-archive.view-archive($url);
    return not-found unless $archive.defined;

    my $title   := “Archive {$archive.url}”;
    my $query   := $archive.meta-name // ‘’;
    my $content := archive-template($archive);
    content ‘text/html’, in-layout(:$title, :$query, :$content);
}
