let
    pkgsSrc = fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/8c09536ef10e72c9421c05403c68134480ba7fde.tar.gz";
        sha256 = "1kf8dl583lbabw93lpc4m5f62pqsip870d8n8hgw06s8898l7mkp";
    };
    pkgsConfig = {
        packageOverrides = pkgs: {
            moar = pkgs.callPackage ./moar.nix {};
            nqp = pkgs.callPackage ./nqp.nix {};
            rakudo = pkgs.callPackage ./rakudo.nix {};
            fireplace = pkgs.callPackage ./fireplace.nix {};
        };
    };
    pkgs = import pkgsSrc {config = pkgsConfig;};
in
    pkgs.fireplace
