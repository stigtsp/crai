unit class CRAI::Database;

use CRAI::Database::Schema;
use CRAI::Database::Upsert;
use CRAI::Util::Hash;
use DBDish::Connection;
use DBIish;

also does CRAI::Database::Upsert;

has DBDish::Connection $.sqlite;
has IO::Path           $.archives;

method new(|c)
{
    die ‘Use CRAI::Database.open instead’;
}

method open(IO::Path:D $path --> ::?CLASS:D)
{
    self.bless(:$path);
}

submethod BUILD(IO::Path:D :$path)
{
    $!archives = $path.child(‘archives’);
    $!archives.mkdir(mode => 0o755);

    $!sqlite = DBIish.connect(‘SQLite’, database => $path.child(‘sqlite’));
    CRAI::Database::Schema::install($!sqlite);
}

method archive-path(::?CLASS:D: Str:D $url --> IO::Path:D)
{
    my $url-hash := sha256-hex($url);
    $!archives.child($url-hash);
}
