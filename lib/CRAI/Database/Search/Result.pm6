unit class CRAI::Database::Search::Result;

has Str   $.meta-name;
has Str   $.meta-version;
has Str   $.meta-description;
has Str   $.meta-license;
has Str:D @.meta-tags;
has Int   $.meta-depends;
