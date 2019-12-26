unit class CRAI::SearchArchives::Result;

use URI::Encode;

has Str   $.url;
has Str   $.meta-name;
has Str   $.meta-version;
has Str   $.meta-description;
has Str   $.meta-license;
has Str:D @.meta-tags;
has Int   $.meta-depends;

method distribution-link(::?CLASS:D: --> Str:D)
{
    with $!meta-name -> $name {
        return “/distribution/{uri_encode($name)}”;
    }
    return self.archive-link;
}

method version-link(::?CLASS:D: --> Str:D)
{
    with $!meta-name -> $name {
        with $!meta-version -> $version {
            return “/distribution/{uri_encode($name)}/{uri_encode($version)}”;
        }
    }
    return self.archive-link;
}

method archive-link(::?CLASS:D: --> Str:D)
{
    “/archive?url={uri_encode($!url)}”;
}
