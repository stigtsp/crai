unit class CRAI::ViewArchive::Archive;

use CRAI::Util::Hash;

has Str $.url;

has Str $.md5-hash;
has Str $.sha1-hash;
has Str $.sha256-hash;

has Str $.meta-name;
has Str $.meta-version;
has Str $.meta-description;
has Str $.meta-source-url;
has Str $.meta-license;

method mirror-url(::?CLASS:D: --> Str:D)
{
    “https://crai.foldr.nl/mirror/{sha256-hex($!url)}”;
}
