Comprehensive Raku Archive Index
================================

The goal of CRAI is to develop
a tool to collect Raku distribution archives
and host them in a central place together with metadata.

Derived goals
-------------

With CRAI, the following guarantees should be easy to implement.
These guarantees are necessary for developing and deploying
secure, production-ready software.

 - Invoking the same installation command multiple times
   results in the same code being installed each time,
   even if new versions of the distribution were published.

 - Distributions that were once available will always remain available,
   even if the author deleted their VCS repository.

 - It is possible to install a specific version of a distribution,
   even if it is very old, and the installation will succeed
   provided it is compatible with the current version of Rakudo.

In addition, the following tooling could be built on top of CRAI:

 - Integration with the Nix package manager.

 - A website which hosts rendered POD for all distributions.

 - All distributions being built and tested on CI
   whenever they come available.

Workings
--------

This repository features a bunch of code to achieve the aforementioned goals.
This code implements the following algorithm:

 1. Retrieve a list of archive URLs.
    Archives are tarballs or zipballs.
    Archive URLs may be retrieved from
    CPAN, ecosystem, and possibly other sources.

 2. Download each archive,
    compute its SHA-256 hash,
    and store it on the CRAI hosting site
    if it has a license that permits redistribution.

 3. Publish metadata about all available versions
    of all available distributions
    in an easy to process format.
    The metadata includes key data from META6.json
    as well as the SHA-256 hash of the archive.

Usage
-----

If you want, you can precompile the application with Nix:

```
$ nix build
$ export PATH=$PATH:$PWD/result/bin
```

The crai command line tool manipulates a database of archives.
This database consists of a SQLite database and a directory of tarballs.
Every subcommand expects the path to this database to be specified:

```bash
crai --database-path ~/crai-database
```

The following subcommands exist. They can be run independently in any order,
but it only really makes sense to run them in the order listed, since later
commands use output generated by previous commands. For more information
about each command, see the source file that is named after it.

 1. [retrieve-archive-list](lib/CRAI/RetrieveArchiveList.pm6)
 2. [retrieve-archives](lib/CRAI/RetrieveArchives.pm6)
 3. [compute-archive-hashes](lib/CRAI/ComputeArchiveHashes.pm6)
 4. [extract-metadata](lib/CRAI/ExtractMetadata.pm6)

The command update-database runs all of these commands in succession.

Source code organization
------------------------

The source code of CRAI is organized by _use case_. A use case is a
particular feature that an actor, such as a user, interacts with. Every
module whose name is a verb implements a use case. Some of these expose
themselves over the command-line, in which case they export a `MAIN` routine,
while others expose a web interface, which is called from `CRAI::Web`.
