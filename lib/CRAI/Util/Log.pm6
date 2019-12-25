unit module CRAI::Util::Log;

use Terminal::ANSIColor;

sub log(Str:D $color, Str:D $status, Str:D $message --> Nil)
    is export
{
    note color($color), “[$status]”, color(‘reset’), ‘ ’, $message;
}
