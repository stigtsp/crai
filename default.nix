let
    pkgs = import ./nix/pkgs.nix {};
in
    pkgs.raku-nix.rakuPackage {
        name = "crai";
        src = pkgs.lib.cleanSource ./.;
        depends = [
            pkgs.raku-nix.Cro-HTTP
            pkgs.raku-nix.DBIish
            pkgs.raku-nix.Inline-Perl5
            pkgs.raku-nix.JSON-Fast
            pkgs.raku-nix.Terminal-ANSIColor
        ];
        preInstallPhase = ''
            # Inline::Perl5 likes to use HOME during compilation.
            mkdir home
            export HOME=$PWD/home

            # Cro::HTTP needs OpenSSL during compilation and at runtime.
            # We also need SQLite at runtime.
            ldLibraryPath=${pkgs.lib.makeLibraryPath [pkgs.openssl pkgs.sqlite]}
            export LD_LIBRARY_PATH=$ldLibraryPath:$LD_LIBRARY_PATH
        '';
        postInstallPhase = ''
            wrapProgram $out/bin/crai \
                --set LD_LIBRARY_PATH $ldLibraryPath \
                --prefix PATH : ${pkgs.curl}/bin \
                --prefix PATH : ${pkgs.git}/bin \
                --prefix PATH : ${pkgs.gnutar}/bin \
                --prefix PATH : ${pkgs.jq}/bin \
                --prefix PATH : ${pkgs.rsync}/bin
        '';
    }
