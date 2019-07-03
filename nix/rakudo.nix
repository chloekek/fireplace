{stdenv, fetchurl, nqp, perl}:
stdenv.mkDerivation rec {
    name = "rakudo-${version}";
    version = "2019.03";
    src = fetchurl {
        url    = "https://rakudostar.com/files/rakudo/${name}.tar.gz";
        sha256 = "13ap3fj1kkfj300nnkvv2f1b1bsa9qg8a1g4y2p6fk2grwy24pfx";
    };
    buildInputs = [nqp perl];
    configureScript = "perl ./Configure.pl";
    configureFlags = [
        "--backends=moar"
        "--with-nqp=${nqp}/bin/nqp"
    ];
}
