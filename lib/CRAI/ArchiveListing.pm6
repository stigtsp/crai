=begin pod

=head1 NAME

CRAI::ArchiveListings - List archives in preparation for download

=head1 SYNOPSIS

=begin code
class MyArchiveListing
     does CRAI::ArchiveListing
{
     method archives(--> Seq:D)
     {
          # Return sequence of URLs.
     }
}
=end code

=head1 DESCRIPTION

An archive listing implements the archives method, which returns a sequence
of archive URLs. An archive is a tarball or zipball containing a Raku
distribution.

The URLs returned by an archive listing are used for populating the database.

An archive listing is expected not to download the archives. Instead, it
should merely return the URLs to the archives. Downloading is handled
separately, so that the downloading of archives can be scheduled separately
from the retrieving of the archive listing.

=head2 @archive-file-extensions

List of file extensions of archives. You can use this if you need to filter a
list of files, e.g. from CPAN. The archive listing itself should take care of
such filtering, and B<not> leave it up to the caller.

=head2 .archives

Stub method that must be overridden. This returns a sequence of strings, each
of which is a URL to an archive. This method is expected to perform
side-effects such as network calls.

=end pod

unit class CRAI::ArchiveListing;

our constant @archive-file-extensions is export =
    <.tar .tar.bz .tar.bz2 .tar.gz .tar.xz
     .tbz .tbz2 .tgz .txz .zip>;

method archives { … }
