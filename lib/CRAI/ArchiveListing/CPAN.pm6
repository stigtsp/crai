=begin pod

=head1 NAME

CRAI::ArchiveListing::CPAN - List all archives on CPAN

=head1 SYNOPSIS

=begin code
# Construction.
my $listing := CRAI::ArchiveListing::CPAN.new;

# Or
my $rsync-url := ‘rsync://cpan-rsync.perl.org/CPAN’;
my $http-url  := ‘https://www.cpan.org’;
my $listing   := CRAI::ArchiveListing::CPAN.new(:$rsync-url, :$http-url);

# Query the object.
say $listing.rsync-url;   # Used for finding archives.
say $listing.http-url;    # Used for creating archive URLs.

# List all archives
my @archives = $listing.archives;
.say for @archives;
=end code

=head1 DESCRIPTION

List all Raku archives on CPAN.

=head1 BUGS

Archives that belong to the PSIXDISTS project are excluded.
They are old, no longer maintained, and there are very many of them.

=end pod

unit class CRAI::ArchiveListing::CPAN;

use CRAI::ArchiveListing;

also is CRAI::ArchiveListing;

has $.rsync-url;
has $.http-url;

multi method new(--> ::?CLASS:D)
{
    self.new(
        :rsync-url<rsync://cpan-rsync.perl.org/CPAN>,
        :http-url<https://www.cpan.org>,
    );
}

multi method new(Str:D :$rsync-url, Str:D :$http-url --> ::?CLASS:D)
{
    self.bless(:$rsync-url, :$http-url);
}

method archives(::?CLASS:D: --> Seq:D)
{
    my @rsync-command := self!rsync-command;
    my $proc := run(@rsync-command, :out);
    self!process-output($proc.out);
}

method !rsync-command(::?CLASS:D: --> List:D)
{
    my @rsync-flags := <--dry-run --verbose --prune-empty-dirs --recursive>;
    my @rsync-includes := ‘*/’, |@archive-file-extensions.map({ “/id/*/*/*/Perl6/*$_” });
    my @rsync-excludes := ‘*’,;
    return (
        ‘rsync’,
        |@rsync-flags,
        |@rsync-includes.map({ “--include=$_” }),
        |@rsync-excludes.map({ “--exclude=$_” }),
        “$!rsync-url/authors/id”,
    );
}

method !process-output(::?CLASS:D: IO::Handle:D $_ --> Seq:D)
{
    .lines
    ==> grep    *.ends-with(any(@archive-file-extensions))
    ==> map     *.split(/\s+/)[4]
    ==> grep    !*.starts-with(‘id/P/PS/PSIXDISTS/’)
    ==> map     “$!http-url/authors/” ~ *
}
