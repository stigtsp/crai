=begin pod

=head1 BUGS

The routines that hash files use O(n) memory.
This is not an inherent problem and may be fixed later.

=end pod

unit module CRAI::Util::Hash;

use OpenSSL::Digest;

################################################################################
# Hashing strings and blobs.

multi generic-hex(&prim, Blob:D $b --> Str:D)
{
    prim($b).list.map(*.fmt(‘%02x’)).join;
}

multi generic-hex(&prim, Str:D $s, Str:D :$encoding = ‘utf8’ --> Str:D)
{
    generic-hex(&prim, $s.encode(:$encoding));
}

sub md5-hex(|c)    is export { generic-hex(&md5, |c) }
sub sha1-hex(|c)   is export { generic-hex(&sha1, |c) }
sub sha256-hex(|c) is export { generic-hex(&sha256, |c) }

################################################################################
# Hashing files.

sub generic-file-hex(&prim, IO() $path --> Str:D)
{
    generic-hex(&prim, $path.slurp(:bin));
}

sub md5-file-hex(|c)    is export { generic-file-hex(&md5, |c) }
sub sha1-file-hex(|c)   is export { generic-file-hex(&sha1, |c) }
sub sha256-file-hex(|c) is export { generic-file-hex(&sha256, |c) }
