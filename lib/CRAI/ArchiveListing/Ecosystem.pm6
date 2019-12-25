=begin pod

=head1 NAME

CRAI::ArchiveListing::Ecosystem - List all archives for the ecosystem repository

=head1 SYNOPSIS

=begin code
# Construction
my $listing := CRAI::ArchiveListing::Ecosystem.new;

# Or
my $projects-json-url := ‘https://ecosystem-api.p6c.org/projects.json’;
my $listing := CRAI::ArchiveListing::Ecosystem.new(:$projects-json-url);

# Query the object
say $listing.projects-json-url;

# List all archives
my @archives = $listing.archives;
.say for @archives;
=end code

=head1 DESCRIPTION

The ecosystem repository lists META6.json files.
This is aggregated into a file called I«projects.json» by a third party.
This class retrieves that file and lists archives for those distributions.

=end pod

unit class CRAI::ArchiveListing::Ecosystem;

use CRAI::ArchiveListing;
use CRAI::ArchiveListing::Aggregate;
use CRAI::ArchiveListing::GitHub;

also is CRAI::ArchiveListing;
also does CRAI::ArchiveListing::Aggregate;

has $.projects-json-url;

multi method new(--> ::?CLASS:D)
{
    self.new(
        :projects-json-url<https://ecosystem-api.p6c.org/projects.json>,
    );
}

multi method new(Str:D :$projects-json-url --> ::?CLASS:D)
{
    self.bless(:$projects-json-url);
}

method archive-listings(::?CLASS:D: --> Seq:D)
{
    self!source-urls.map: {
        my $github := try CRAI::ArchiveListing::GitHub.new(:url($_));
        $! ?? do { warn $!; Empty } !! $github;
    };
}

method !source-urls(::?CLASS:D: --> Seq:D)
{
    my @curl := <curl --silent --show-error>;
    my @jq   := <jq --raw-output>;

    my $curl := run(@curl, $!projects-json-url, :out);
    my $jq   := run(@jq, q:to/JQ/, :in($curl.out), :out);
        map(."source-url" | strings) | join("\n")
        JQ

    $jq.out.lines;
}
